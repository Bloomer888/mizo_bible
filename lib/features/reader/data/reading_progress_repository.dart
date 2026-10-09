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
    await (db.update(db.readingProgress)..where((p) => p.id.equals(existing.id))).write(
      ReadingProgressCompanion(
        chapter: Value(chapter),
        verse: Value(verse),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
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
