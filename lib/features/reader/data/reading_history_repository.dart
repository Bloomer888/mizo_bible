import 'package:uuid/uuid.dart';

import '../../../core/db/user_database.dart';

const _uuid = Uuid();

/// Append-only, unlike reading_progress (one row per book, always
/// updated in place) -- a log of chapters visited over time. Used to
/// power both a browsable History page and the reading streak;
/// History was removed 2026-10-12 (redundant with bookmarks + the
/// streak's week-strip), and the streak itself moved 2026-10-13 to an
/// explicit manual check-in (streak_repository.dart) instead of being
/// derived from chapters visited here -- that also fixed a real bug,
/// the streak card disappearing entirely once it hit zero. This log
/// keeps recording regardless: dormant for now, but cheap, and still
/// the natural source for a future "recently read" feature, which was
/// the original second reason this table existed alongside the streak,
/// not an afterthought invented to justify not deleting it. Skips
/// inserting when the most recent entry is already this exact chapter,
/// so re-entering the same chapter repeatedly in one sitting doesn't
/// flood the log with duplicates.
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
