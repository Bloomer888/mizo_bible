import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/user_database.dart';

const _uuid = Uuid();

/// Bookmarks, highlights, and notes together -- not split one-file-per-
/// table like reading_progress/settings, because all three are surfaced
/// from the exact same place (a verse's long-press action sheet) and are
/// read together as one combined state per verse (see
/// [loadVerseAnnotations]/[VerseAnnotations]) every time a row renders.

class VerseAnnotations {
  final bool bookmarked;
  final String? highlightColor;
  final bool hasNote;
  const VerseAnnotations({required this.bookmarked, required this.highlightColor, required this.hasNote});

  static const none = VerseAnnotations(bookmarked: false, highlightColor: null, hasNote: false);
}

Future<VerseAnnotations> loadVerseAnnotations(
  UserDatabase db, {
  required int bookId,
  required int chapter,
  required int verse,
}) async {
  final bookmark = await (db.select(db.bookmarks)
        ..where((b) => b.bookId.equals(bookId) & b.chapter.equals(chapter) & b.verse.equals(verse) & b.deleted.equals(false))
        ..limit(1))
      .getSingleOrNull();
  final highlight = await (db.select(db.highlights)
        ..where((h) => h.bookId.equals(bookId) & h.chapter.equals(chapter) & h.verse.equals(verse) & h.deleted.equals(false))
        ..limit(1))
      .getSingleOrNull();
  final note = await (db.select(db.notes)
        ..where((n) => n.bookId.equals(bookId) & n.chapter.equals(chapter) & n.verse.equals(verse) & n.deleted.equals(false))
        ..limit(1))
      .getSingleOrNull();

  return VerseAnnotations(
    bookmarked: bookmark != null,
    highlightColor: highlight?.color,
    hasNote: note != null,
  );
}

// --- Bookmarks ---------------------------------------------------------

Future<void> toggleBookmark(UserDatabase db, {required int bookId, required int chapter, required int verse}) async {
  // Deliberately NOT filtered to deleted.equals(false) -- toggling a
  // bookmark off then back on must revive that same tombstoned row, not
  // insert a second one alongside it. (Caught by a test: filtering here
  // found no row to revive on the second toggle and inserted a fresh
  // one instead, leaving two rows for one verse.)
  final existing = await (db.select(db.bookmarks)
        ..where((b) => b.bookId.equals(bookId) & b.chapter.equals(chapter) & b.verse.equals(verse))
        ..limit(1))
      .getSingleOrNull();

  if (existing != null) {
    // Flips deleted rather than assuming it was false -- this is a
    // toggle, so the row found here could be either state. A tombstone,
    // not a real delete when turning a bookmark off -- see
    // SyncableColumns' doc comment in user_database.dart for why (Phase
    // 8 sync needs something to propagate the removal with).
    await (db.update(db.bookmarks)..where((b) => b.id.equals(existing.id))).write(
      BookmarksCompanion(
        deleted: Value(!existing.deleted),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  } else {
    await db.into(db.bookmarks).insert(
          BookmarksCompanion.insert(id: _uuid.v4(), bookId: bookId, chapter: chapter, verse: verse),
        );
  }
}

class BookmarkEntry {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final DateTime createdAt;
  const BookmarkEntry({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.createdAt,
  });
}

Future<List<BookmarkEntry>> loadAllBookmarks(UserDatabase userDb, Map<int, String> bookNames) async {
  final rows = await (userDb.select(userDb.bookmarks)
        ..where((b) => b.deleted.equals(false))
        ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
      .get();
  return [
    for (final r in rows)
      BookmarkEntry(
        bookId: r.bookId,
        bookName: bookNames[r.bookId] ?? '?',
        chapter: r.chapter,
        verse: r.verse,
        createdAt: r.createdAt,
      ),
  ];
}

// --- Highlights ----------------------------------------------------------

/// Palette keys, not packed colors -- see Highlights' own doc comment in
/// user_database.dart. The actual Color values live with the UI
/// (verse_actions_sheet.dart) since that's the only place that renders
/// them; this layer only ever stores/returns the key string.
const highlightColorKeys = ['yellow', 'green', 'blue', 'pink', 'orange'];

Future<void> setHighlight(
  UserDatabase db, {
  required int bookId,
  required int chapter,
  required int verse,
  required String color,
}) async {
  final existing = await (db.select(db.highlights)
        ..where((h) => h.bookId.equals(bookId) & h.chapter.equals(chapter) & h.verse.equals(verse))
        ..limit(1))
      .getSingleOrNull();

  if (existing != null) {
    await (db.update(db.highlights)..where((h) => h.id.equals(existing.id))).write(
      HighlightsCompanion(
        color: Value(color),
        deleted: const Value(false),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  } else {
    await db.into(db.highlights).insert(
          HighlightsCompanion.insert(id: _uuid.v4(), bookId: bookId, chapter: chapter, verse: verse, color: color),
        );
  }
}

Future<void> removeHighlight(UserDatabase db, {required int bookId, required int chapter, required int verse}) async {
  await (db.update(db.highlights)
        ..where((h) => h.bookId.equals(bookId) & h.chapter.equals(chapter) & h.verse.equals(verse)))
      .write(HighlightsCompanion(deleted: const Value(true), updatedAt: Value(DateTime.now()), dirty: const Value(true)));
}

class HighlightEntry {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String color;
  const HighlightEntry({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.color,
  });
}

Future<List<HighlightEntry>> loadAllHighlights(UserDatabase userDb, Map<int, String> bookNames) async {
  final rows = await (userDb.select(userDb.highlights)
        ..where((h) => h.deleted.equals(false))
        ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
      .get();
  return [
    for (final r in rows)
      HighlightEntry(bookId: r.bookId, bookName: bookNames[r.bookId] ?? '?', chapter: r.chapter, verse: r.verse, color: r.color),
  ];
}

// --- Notes ---------------------------------------------------------------

Future<String?> loadNoteText(UserDatabase db, {required int bookId, required int chapter, required int verse}) async {
  final row = await (db.select(db.notes)
        ..where((n) => n.bookId.equals(bookId) & n.chapter.equals(chapter) & n.verse.equals(verse) & n.deleted.equals(false))
        ..limit(1))
      .getSingleOrNull();
  return row?.content;
}

Future<void> saveNote(
  UserDatabase db, {
  required int bookId,
  required int chapter,
  required int verse,
  required String text,
}) async {
  final existing = await (db.select(db.notes)
        ..where((n) => n.bookId.equals(bookId) & n.chapter.equals(chapter) & n.verse.equals(verse))
        ..limit(1))
      .getSingleOrNull();

  if (existing != null) {
    await (db.update(db.notes)..where((n) => n.id.equals(existing.id))).write(
      NotesCompanion(
        content: Value(text),
        deleted: const Value(false),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  } else {
    await db.into(db.notes).insert(
          NotesCompanion.insert(id: _uuid.v4(), bookId: bookId, chapter: chapter, verse: verse, content: text),
        );
  }
}

Future<void> deleteNote(UserDatabase db, {required int bookId, required int chapter, required int verse}) async {
  await (db.update(db.notes)..where((n) => n.bookId.equals(bookId) & n.chapter.equals(chapter) & n.verse.equals(verse)))
      .write(NotesCompanion(deleted: const Value(true), updatedAt: Value(DateTime.now()), dirty: const Value(true)));
}

class NoteEntry {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  const NoteEntry({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });
}

Future<List<NoteEntry>> loadAllNotes(UserDatabase userDb, Map<int, String> bookNames) async {
  final rows = await (userDb.select(userDb.notes)
        ..where((n) => n.deleted.equals(false))
        ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
      .get();
  return [
    for (final r in rows)
      NoteEntry(bookId: r.bookId, bookName: bookNames[r.bookId] ?? '?', chapter: r.chapter, verse: r.verse, text: r.content),
  ];
}
