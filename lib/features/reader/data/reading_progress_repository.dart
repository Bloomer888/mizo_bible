import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/user_database.dart';

const _uuid = Uuid();

/// One row per book: finds the existing row (if any) and updates it
/// rather than inserting a fresh one each time -- see ReadingProgress's
/// own doc comment in user_database.dart for why this is the
/// application's job right now, not a DB-level constraint. limit(1)
/// makes the lookup safe even if a future bug somehow left duplicates,
/// where a plain getSingleOrNull would throw.
Future<void> saveReadingProgress(
  UserDatabase db, {
  required int bookId,
  required int chapter,
  required int verse,
}) async {
  final existing = await (db.select(db.readingProgress)
        ..where((p) => p.bookId.equals(bookId))
        ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
        ..limit(1))
      .getSingleOrNull();

  if (existing != null) {
    // Delete-and-reinsert rather than updating in place: an in-place
    // update leaves the row's rowid untouched even though it was just
    // touched, which is exactly backwards for
    // loadMostRecentReadingProgress's cross-book "most recently
    // touched" ordering -- caught by a test, the same stored-precision
    // tie class already hit once for reading_history, just without
    // that fix's rowid trick being valid here (this table isn't
    // append-only) until the row itself gets a fresh rowid on every
    // touch. created_at carries over so it still means "first opened
    // this book," not "last touched."
    await db.transaction(() async {
      await (db.delete(db.readingProgress)..where((p) => p.id.equals(existing.id))).go();
      await db.into(db.readingProgress).insert(
            ReadingProgressCompanion.insert(
              id: _uuid.v4(),
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              createdAt: Value(existing.createdAt),
            ),
          );
    });
  } else {
    await db.into(db.readingProgress).insert(
          ReadingProgressCompanion.insert(id: _uuid.v4(), bookId: bookId, chapter: chapter, verse: verse),
        );
  }
}

typedef ReadingPosition = ({int chapter, int verse});

Future<ReadingPosition?> loadReadingProgress(UserDatabase db, int bookId) async {
  final row = await (db.select(db.readingProgress)
        ..where((p) => p.bookId.equals(bookId) & p.deleted.equals(false))
        ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
        ..limit(1))
      .getSingleOrNull();
  if (row == null) return null;
  return (chapter: row.chapter, verse: row.verse);
}

typedef BookReadingPosition = ({int bookId, int chapter, int verse});

/// The single most recently touched book, for the Home tab's "Continue
/// reading" card -- unlike [loadReadingProgress], not scoped to one
/// book, since Home doesn't know which book to ask about yet.
///
/// rowid, not updated_at, for the same reason saveReadingProgress now
/// deletes and reinserts on every touch: two saves landing in the same
/// wall-clock second tie on updated_at's stored precision, and rowid
/// is the one thing here that's actually guaranteed to reflect "most
/// recently touched" now that every touch is a fresh row.
Future<BookReadingPosition?> loadMostRecentReadingProgress(UserDatabase db) async {
  final rows = await db.customSelect(
    'select book_id, chapter, verse from reading_progress where deleted = 0 order by rowid desc limit 1',
    readsFrom: {db.readingProgress},
  ).get();
  if (rows.isEmpty) return null;
  final row = rows.single;
  return (bookId: row.read<int>('book_id'), chapter: row.read<int>('chapter'), verse: row.read<int>('verse'));
}
