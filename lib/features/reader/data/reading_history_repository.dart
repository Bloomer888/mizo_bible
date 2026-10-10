import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/user_database.dart';

const _uuid = Uuid();

/// Append-only, unlike reading_progress (one row per book, always
/// updated in place) -- this is a log of chapters visited over time, so
/// "recently read" can show real history, not just the current spot.
/// Skips inserting when the most recent entry is already this exact
/// chapter, so re-entering the same chapter repeatedly in one sitting
/// doesn't flood the log with duplicates.
Future<void> logChapterVisit(UserDatabase db, {required int bookId, required int chapter}) async {
  // Raw SQL ordering by rowid, not Drift's typed query builder ordering
  // by createdAt -- caught by a test: two inserts landing in the same
  // wall-clock second (plausible even outside tests, and trivial in
  // rapid-fire test code) tie on createdAt, and SQLite doesn't promise
  // any particular tie-break order, so "most recent" became unreliable
  // right when this check needs it most. rowid is genuinely monotonic
  // with insertion order, which createdAt's stored precision isn't.
  final lastRows = await db
      .customSelect(
        'select book_id, chapter from reading_history order by rowid desc limit 1',
        readsFrom: {db.readingHistory},
      )
      .get();

  if (lastRows.isNotEmpty) {
    final last = lastRows.single;
    if (last.read<int>('book_id') == bookId && last.read<int>('chapter') == chapter) return;
  }

  await db.into(db.readingHistory).insert(
        ReadingHistoryCompanion.insert(id: _uuid.v4(), bookId: bookId, chapter: chapter),
      );
}

class HistoryEntry {
  final int bookId;
  final String bookName;
  final int chapter;
  final DateTime visitedAt;
  const HistoryEntry({required this.bookId, required this.bookName, required this.chapter, required this.visitedAt});
}

Future<List<HistoryEntry>> loadHistory(UserDatabase db, Map<int, String> bookNames, {int limit = 200}) async {
  // rowid, not createdAt, for the same reason as logChapterVisit's own
  // "most recent" check: two visits can tie on createdAt's stored
  // precision, and ORDER BY created_at DESC then has no guaranteed
  // tie-break, so "most recent first" stopped being reliably true right
  // when a user would actually notice -- the chapter they just left not
  // showing up first. (Caught by a test asserting history.first after
  // two visits in quick succession -- display order is a real
  // expectation here, not just cosmetic, same as the dedup check.)
  final rows = await db
      .customSelect(
        'select book_id, chapter, created_at from reading_history where deleted = 0 order by rowid desc limit ?',
        variables: [Variable.withInt(limit)],
        readsFrom: {db.readingHistory},
      )
      .get();

  return [
    for (final r in rows)
      HistoryEntry(
        bookId: r.read<int>('book_id'),
        bookName: bookNames[r.read<int>('book_id')] ?? '?',
        chapter: r.read<int>('chapter'),
        visitedAt: r.read<DateTime>('created_at'),
      ),
  ];
}
