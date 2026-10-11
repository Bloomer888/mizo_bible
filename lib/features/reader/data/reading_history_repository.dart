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

/// Current daily reading streak: consecutive calendar days (local
/// time) with at least one reading_history entry, counting back from
/// today. One grace day built in -- if the most recent entry was
/// yesterday rather than today, the streak still shows (today isn't
/// over yet) rather than dropping to zero the moment a new day starts
/// before they've opened the app.
///
/// No new table or column: this is a read over data reading_history
/// already stores for the history list, so a per-user streak costs
/// nothing beyond what's already there. .toLocal() is deliberate, not
/// defensive dead code -- a streak must count calendar days as this
/// device's owner experiences them, not whatever timezone the stored
/// timestamp's raw value happens to be in.
Future<int> loadReadingStreak(UserDatabase db) async {
  final rows = await db
      .customSelect(
        'select created_at from reading_history where deleted = 0 order by rowid desc limit 2000',
        readsFrom: {db.readingHistory},
      )
      .get();

  final days = <DateTime>{};
  for (final row in rows) {
    final local = row.read<DateTime>('created_at').toLocal();
    days.add(DateTime(local.year, local.month, local.day));
  }
  if (days.isEmpty) return 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var cursor = days.contains(today) ? today : today.subtract(const Duration(days: 1));
  if (!days.contains(cursor)) return 0;

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Which days in the current Monday-start calendar week (through
/// today) have at least one reading_history entry -- powers the
/// streak week-strip on Home. Never contains a day after today: a
/// day that hasn't happened yet can't have been read, so the caller
/// doesn't need to special-case "future" by checking this set, only
/// by comparing the date itself.
///
/// A separate, smaller query from [loadReadingStreak] rather than
/// sharing one -- both read the same table, but at this app's scale a
/// second cheap query is simpler than threading one shared result
/// through two different shapes of "which days" logic.
Future<Set<DateTime>> loadReadingDaysThisWeek(UserDatabase db) async {
  final rows = await db
      .customSelect(
        'select created_at from reading_history where deleted = 0 order by rowid desc limit 200',
        readsFrom: {db.readingHistory},
      )
      .get();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  final days = <DateTime>{};
  for (final row in rows) {
    final local = row.read<DateTime>('created_at').toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (!day.isBefore(weekStart) && !day.isAfter(today)) {
      days.add(day);
    }
  }
  return days;
}
