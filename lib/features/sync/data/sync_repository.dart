import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/user_database.dart';
import '../../auth/data/auth_repository.dart';

const _schema = 'user_data';

/// Claims any still-unclaimed local rows, pushes everything locally
/// dirty, then pulls the signed-in user's full remote dataset down and
/// reconciles it into the local database. Safe to call repeatedly --
/// e.g. on every app launch/resume while signed in, not just once at
/// sign-in -- since claiming and pulling are both idempotent, and push
/// only ever sends rows actually marked dirty.
///
/// Re-claiming on every call (not just once at sign-in) matters: a
/// bookmark added *after* signing in still starts with a null userId,
/// the same as any other new row (see SyncableColumns' doc comment) --
/// nothing stamps it at creation time. Without claiming again here,
/// that row would never become eligible to push and would be silently
/// stranded, local-only, forever.
Future<void> syncUserData(UserDatabase db, String userId) async {
  await claimLocalRows(db, userId);

  final client = Supabase.instance.client;
  await _pushBookmarks(db, client);
  await _pushHighlights(db, client);
  await _pushNotes(db, client);
  await _pushReadingHistory(db, client);
  await _pushReadingProgress(db, client);
  await _pushSettings(db, client);

  await _pullBookmarks(db, client);
  await _pullHighlights(db, client);
  await _pullNotes(db, client);
  await _pullReadingHistory(db, client);
  await _pullReadingProgress(db, client);
  await _pullSettings(db, client);
}

/// Tombstones every row for this user, best-effort pushes those
/// tombstones to the server, then hard-deletes this user's rows (and
/// only this user's rows -- see the second test below) from the local
/// database. Called from the Account screen's "Delete my data" action.
///
/// Tombstoning (not a real DELETE) is all the server push can ever do:
/// the Phase 8 migration only grants `authenticated` select/insert/
/// update on user_data.* -- deliberately no delete, the same "only
/// ever soft-delete" rule every other table in this app already
/// follows. A full, permanent purge of tombstoned rows needs an
/// elevated-privilege process this app doesn't have (there's no admin
/// panel or server-side function yet) -- the Privacy Policy is worded
/// to reflect that two-step reality rather than promise something this
/// code can't actually do.
///
/// The local wipe happens regardless of whether the push succeeded --
/// if there's no network right now, the user still asked for their
/// data gone from *this* device immediately, and local rows marked
/// dirty would otherwise just sit there forever with no further sync
/// ever triggered to retry them (there's no background retry queue).
Future<void> deleteAllUserData(UserDatabase db, String userId) async {
  await db.transaction(() async {
    const tombstone = true;
    await (db.update(db.bookmarks)..where((t) => t.userId.equals(userId)))
        .write(const BookmarksCompanion(deleted: Value(tombstone), dirty: Value(true)));
    await (db.update(db.highlights)..where((t) => t.userId.equals(userId)))
        .write(const HighlightsCompanion(deleted: Value(tombstone), dirty: Value(true)));
    await (db.update(db.notes)..where((t) => t.userId.equals(userId)))
        .write(const NotesCompanion(deleted: Value(tombstone), dirty: Value(true)));
    await (db.update(db.readingHistory)..where((t) => t.userId.equals(userId)))
        .write(const ReadingHistoryCompanion(deleted: Value(tombstone), dirty: Value(true)));
    await (db.update(db.readingProgress)..where((t) => t.userId.equals(userId)))
        .write(const ReadingProgressCompanion(deleted: Value(tombstone), dirty: Value(true)));
    await (db.update(db.settings)..where((t) => t.userId.equals(userId)))
        .write(const SettingsCompanion(deleted: Value(tombstone), dirty: Value(true)));
  });

  try {
    final client = Supabase.instance.client;
    await _pushBookmarks(db, client);
    await _pushHighlights(db, client);
    await _pushNotes(db, client);
    await _pushReadingHistory(db, client);
    await _pushReadingProgress(db, client);
    await _pushSettings(db, client);
  } catch (_) {
    // Best effort -- the local wipe below happens unconditionally.
  }

  await db.transaction(() async {
    await (db.delete(db.bookmarks)..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.highlights)..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.notes)..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.readingHistory)..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.readingProgress)..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.settings)..where((t) => t.userId.equals(userId))).go();
  });
}

// --- Bookmarks -------------------------------------------------------

Future<void> _pushBookmarks(UserDatabase db, SupabaseClient client) async {
  final dirty = await (db.select(db.bookmarks)..where((b) => b.dirty.equals(true))).get();
  if (dirty.isEmpty) return;
  await client.schema(_schema).from('bookmarks').upsert(
        [for (final r in dirty) _bookmarkToRemote(r)],
        onConflict: 'user_id,book_id,chapter,verse',
      );
  await (db.update(db.bookmarks)..where((b) => b.id.isIn(dirty.map((r) => r.id))))
      .write(const BookmarksCompanion(dirty: Value(false)));
}

Map<String, dynamic> _bookmarkToRemote(Bookmark r) => {
      'id': r.id,
      'user_id': r.userId,
      'book_id': r.bookId,
      'chapter': r.chapter,
      'verse': r.verse,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'deleted': r.deleted,
    };

Future<void> _pullBookmarks(UserDatabase db, SupabaseClient client) async {
  final remote = await client.schema(_schema).from('bookmarks').select();
  await applyPulledBookmarks(db, remote);
}

/// Reconciles already-fetched remote rows into the local table --
/// split from [_pullBookmarks] so this, the part with real decisions
/// to get right, is testable without a network call or a mock backend.
///
/// A remote row matching an existing local row by business key (book,
/// chapter, verse) replaces it, *adopting the remote id*, rather than
/// being inserted alongside it: two devices that each bookmarked the
/// same verse before either had ever synced would otherwise converge
/// on two rows for one verse forever, the same duplicate-row bug class
/// already caught once in toggleBookmark (see verse_annotations_
/// repository.dart) -- this is that fix applied to the sync path too.
Future<void> applyPulledBookmarks(UserDatabase db, List<Map<String, dynamic>> remote) async {
  for (final row in remote) {
    final bookId = row['book_id'] as int;
    final chapter = row['chapter'] as int;
    final verse = row['verse'] as int;
    final remoteId = row['id'] as String;

    final existing = await (db.select(db.bookmarks)
          ..where((b) => b.bookId.equals(bookId) & b.chapter.equals(chapter) & b.verse.equals(verse)))
        .getSingleOrNull();
    if (existing != null && existing.id != remoteId) {
      await (db.delete(db.bookmarks)..where((b) => b.id.equals(existing.id))).go();
    }

    await db.into(db.bookmarks).insertOnConflictUpdate(BookmarksCompanion(
          id: Value(remoteId),
          userId: Value(row['user_id'] as String),
          bookId: Value(bookId),
          chapter: Value(chapter),
          verse: Value(verse),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          deleted: Value(row['deleted'] as bool),
          dirty: const Value(false),
        ));
  }
}

// --- Highlights --------------------------------------------------------

Future<void> _pushHighlights(UserDatabase db, SupabaseClient client) async {
  final dirty = await (db.select(db.highlights)..where((h) => h.dirty.equals(true))).get();
  if (dirty.isEmpty) return;
  await client.schema(_schema).from('highlights').upsert(
        [for (final r in dirty) _highlightToRemote(r)],
        onConflict: 'user_id,book_id,chapter,verse',
      );
  await (db.update(db.highlights)..where((h) => h.id.isIn(dirty.map((r) => r.id))))
      .write(const HighlightsCompanion(dirty: Value(false)));
}

Map<String, dynamic> _highlightToRemote(Highlight r) => {
      'id': r.id,
      'user_id': r.userId,
      'book_id': r.bookId,
      'chapter': r.chapter,
      'verse': r.verse,
      'color': r.color,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'deleted': r.deleted,
    };

Future<void> _pullHighlights(UserDatabase db, SupabaseClient client) async {
  final remote = await client.schema(_schema).from('highlights').select();
  await applyPulledHighlights(db, remote);
}

/// See [applyPulledBookmarks] for why a business-key match replaces
/// (rather than sits alongside) an existing local row.
Future<void> applyPulledHighlights(UserDatabase db, List<Map<String, dynamic>> remote) async {
  for (final row in remote) {
    final bookId = row['book_id'] as int;
    final chapter = row['chapter'] as int;
    final verse = row['verse'] as int;
    final remoteId = row['id'] as String;

    final existing = await (db.select(db.highlights)
          ..where((h) => h.bookId.equals(bookId) & h.chapter.equals(chapter) & h.verse.equals(verse)))
        .getSingleOrNull();
    if (existing != null && existing.id != remoteId) {
      await (db.delete(db.highlights)..where((h) => h.id.equals(existing.id))).go();
    }

    await db.into(db.highlights).insertOnConflictUpdate(HighlightsCompanion(
          id: Value(remoteId),
          userId: Value(row['user_id'] as String),
          bookId: Value(bookId),
          chapter: Value(chapter),
          verse: Value(verse),
          color: Value(row['color'] as String),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          deleted: Value(row['deleted'] as bool),
          dirty: const Value(false),
        ));
  }
}

// --- Notes ---------------------------------------------------------------

Future<void> _pushNotes(UserDatabase db, SupabaseClient client) async {
  final dirty = await (db.select(db.notes)..where((n) => n.dirty.equals(true))).get();
  if (dirty.isEmpty) return;
  await client.schema(_schema).from('notes').upsert(
        [for (final r in dirty) _noteToRemote(r)],
        onConflict: 'user_id,book_id,chapter,verse',
      );
  await (db.update(db.notes)..where((n) => n.id.isIn(dirty.map((r) => r.id))))
      .write(const NotesCompanion(dirty: Value(false)));
}

Map<String, dynamic> _noteToRemote(Note r) => {
      'id': r.id,
      'user_id': r.userId,
      'book_id': r.bookId,
      'chapter': r.chapter,
      'verse': r.verse,
      'content': r.content,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'deleted': r.deleted,
    };

Future<void> _pullNotes(UserDatabase db, SupabaseClient client) async {
  final remote = await client.schema(_schema).from('notes').select();
  await applyPulledNotes(db, remote);
}

/// See [applyPulledBookmarks] for why a business-key match replaces
/// (rather than sits alongside) an existing local row.
Future<void> applyPulledNotes(UserDatabase db, List<Map<String, dynamic>> remote) async {
  for (final row in remote) {
    final bookId = row['book_id'] as int;
    final chapter = row['chapter'] as int;
    final verse = row['verse'] as int;
    final remoteId = row['id'] as String;

    final existing = await (db.select(db.notes)
          ..where((n) => n.bookId.equals(bookId) & n.chapter.equals(chapter) & n.verse.equals(verse)))
        .getSingleOrNull();
    if (existing != null && existing.id != remoteId) {
      await (db.delete(db.notes)..where((n) => n.id.equals(existing.id))).go();
    }

    await db.into(db.notes).insertOnConflictUpdate(NotesCompanion(
          id: Value(remoteId),
          userId: Value(row['user_id'] as String),
          bookId: Value(bookId),
          chapter: Value(chapter),
          verse: Value(verse),
          content: Value(row['content'] as String),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          deleted: Value(row['deleted'] as bool),
          dirty: const Value(false),
        ));
  }
}

// --- Reading history -------------------------------------------------

Future<void> _pushReadingHistory(UserDatabase db, SupabaseClient client) async {
  final dirty = await (db.select(db.readingHistory)..where((h) => h.dirty.equals(true))).get();
  if (dirty.isEmpty) return;
  // Plain id upsert, not a business-key one -- reading_history is an
  // append-only log by design (see user_database.dart), so there's no
  // business key to converge on, only the row's own immutable id.
  await client.schema(_schema).from('reading_history').upsert(
        [for (final r in dirty) _historyToRemote(r)],
        onConflict: 'id',
      );
  await (db.update(db.readingHistory)..where((h) => h.id.isIn(dirty.map((r) => r.id))))
      .write(const ReadingHistoryCompanion(dirty: Value(false)));
}

Map<String, dynamic> _historyToRemote(ReadingHistoryData r) => {
      'id': r.id,
      'user_id': r.userId,
      'book_id': r.bookId,
      'chapter': r.chapter,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'deleted': r.deleted,
    };

Future<void> _pullReadingHistory(UserDatabase db, SupabaseClient client) async {
  final remote = await client.schema(_schema).from('reading_history').select();
  await applyPulledReadingHistory(db, remote);
}

/// No business-key reconciliation needed here, unlike the per-verse
/// tables -- an append-only log has no business key to converge on,
/// so this is a plain upsert by id (a visit logged on two devices
/// before either synced just ends up as two entries, which is already
/// correct: the log is explicitly not deduped across visits, only
/// immediate same-chapter repeats on one device -- see
/// reading_history_repository.dart's logChapterVisit).
Future<void> applyPulledReadingHistory(UserDatabase db, List<Map<String, dynamic>> remote) async {
  for (final row in remote) {
    await db.into(db.readingHistory).insertOnConflictUpdate(ReadingHistoryCompanion(
          id: Value(row['id'] as String),
          userId: Value(row['user_id'] as String),
          bookId: Value(row['book_id'] as int),
          chapter: Value(row['chapter'] as int),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          deleted: Value(row['deleted'] as bool),
          dirty: const Value(false),
        ));
  }
}

// --- Reading progress --------------------------------------------------

Future<void> _pushReadingProgress(UserDatabase db, SupabaseClient client) async {
  final dirty = await (db.select(db.readingProgress)..where((p) => p.dirty.equals(true))).get();
  if (dirty.isEmpty) return;
  await client.schema(_schema).from('reading_progress').upsert(
        [for (final r in dirty) _progressToRemote(r)],
        onConflict: 'user_id,book_id',
      );
  await (db.update(db.readingProgress)..where((p) => p.id.isIn(dirty.map((r) => r.id))))
      .write(const ReadingProgressCompanion(dirty: Value(false)));
}

Map<String, dynamic> _progressToRemote(ReadingProgressData r) => {
      'id': r.id,
      'user_id': r.userId,
      'book_id': r.bookId,
      'chapter': r.chapter,
      'verse': r.verse,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'deleted': r.deleted,
    };

Future<void> _pullReadingProgress(UserDatabase db, SupabaseClient client) async {
  final remote = await client.schema(_schema).from('reading_progress').select();
  await applyPulledReadingProgress(db, remote);
}

/// Business key is book alone (one progress row per book -- see
/// ReadingProgress's doc comment in user_database.dart), not book plus
/// chapter/verse like the per-verse tables.
Future<void> applyPulledReadingProgress(UserDatabase db, List<Map<String, dynamic>> remote) async {
  for (final row in remote) {
    final bookId = row['book_id'] as int;
    final remoteId = row['id'] as String;

    final existing = await (db.select(db.readingProgress)..where((p) => p.bookId.equals(bookId))).getSingleOrNull();
    if (existing != null && existing.id != remoteId) {
      await (db.delete(db.readingProgress)..where((p) => p.id.equals(existing.id))).go();
    }

    await db.into(db.readingProgress).insertOnConflictUpdate(ReadingProgressCompanion(
          id: Value(remoteId),
          userId: Value(row['user_id'] as String),
          bookId: Value(bookId),
          chapter: Value(row['chapter'] as int),
          verse: Value(row['verse'] as int),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          deleted: Value(row['deleted'] as bool),
          dirty: const Value(false),
        ));
  }
}

// --- Settings ------------------------------------------------------------

Future<void> _pushSettings(UserDatabase db, SupabaseClient client) async {
  final dirty = await (db.select(db.settings)..where((s) => s.dirty.equals(true))).get();
  if (dirty.isEmpty) return;
  await client.schema(_schema).from('settings').upsert(
        [for (final r in dirty) _settingToRemote(r)],
        onConflict: 'user_id,key',
      );
  await (db.update(db.settings)..where((s) => s.id.isIn(dirty.map((r) => r.id))))
      .write(const SettingsCompanion(dirty: Value(false)));
}

Map<String, dynamic> _settingToRemote(Setting r) => {
      'id': r.id,
      'user_id': r.userId,
      'key': r.key,
      'value': r.value,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'deleted': r.deleted,
    };

Future<void> _pullSettings(UserDatabase db, SupabaseClient client) async {
  final remote = await client.schema(_schema).from('settings').select();
  await applyPulledSettings(db, remote);
}

/// Business key is the setting's key alone (one row per key -- see
/// settings_repository.dart's own find-or-update pattern).
Future<void> applyPulledSettings(UserDatabase db, List<Map<String, dynamic>> remote) async {
  for (final row in remote) {
    final key = row['key'] as String;
    final remoteId = row['id'] as String;

    final existing = await (db.select(db.settings)..where((s) => s.key.equals(key))).getSingleOrNull();
    if (existing != null && existing.id != remoteId) {
      await (db.delete(db.settings)..where((s) => s.id.equals(existing.id))).go();
    }

    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
          id: Value(remoteId),
          userId: Value(row['user_id'] as String),
          key: Value(key),
          value: Value(row['value'] as String),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          deleted: Value(row['deleted'] as bool),
          dirty: const Value(false),
        ));
  }
}
