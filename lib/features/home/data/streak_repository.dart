import 'package:uuid/uuid.dart';

import '../../../core/db/user_database.dart';

const _uuid = Uuid();

/// Today's calendar day at local midnight -- every function below
/// normalizes to this before touching streak_checkins, so a lookup is
/// always a plain equality check against a stored DateTime, never a
/// range query.
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<bool> isCheckedInToday(UserDatabase db) async {
  final row = await (db.select(db.streakCheckins)..where((t) => t.day.equals(_today()))).getSingleOrNull();
  return row != null;
}

/// Marks today as read. Idempotent -- a second tap the same day (or a
/// retry after a dropped connection to a future synced version of this
/// table) finds the existing row and does nothing rather than risk a
/// duplicate, same find-or-skip reasoning as every other table in this
/// database that could otherwise double-insert for one logical day.
Future<void> checkInToday(UserDatabase db) async {
  final today = _today();
  final existing = await (db.select(db.streakCheckins)..where((t) => t.day.equals(today))).getSingleOrNull();
  if (existing != null) return;
  await db.into(db.streakCheckins).insert(StreakCheckinsCompanion.insert(id: _uuid.v4(), day: today));
}

Future<Set<DateTime>> _allCheckinDays(UserDatabase db) async {
  final rows = await (db.select(db.streakCheckins)..where((t) => t.deleted.equals(false))).get();
  return {for (final r in rows) r.day};
}

/// Current consecutive-day streak, counting back from today. One grace
/// day built in: if today isn't checked in yet but yesterday was, the
/// streak still shows (today isn't over) rather than dropping to zero
/// the moment a new day starts before the user has had a chance to tap
/// in -- same reasoning the old reading-history-derived streak used,
/// still correct now that the day is marked manually instead of
/// inferred from reading activity.
Future<int> loadStreak(UserDatabase db) async {
  final days = await _allCheckinDays(db);
  if (days.isEmpty) return 0;

  final today = _today();
  var cursor = days.contains(today) ? today : today.subtract(const Duration(days: 1));
  if (!days.contains(cursor)) return 0;

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// The longest run of consecutive checked-in days ever, not just the
/// current one -- the "personal best" stat alongside the live streak,
/// the way most habit/streak apps show both rather than only the
/// number that can currently go up or down.
Future<int> loadBestStreak(UserDatabase db) async {
  final days = await _allCheckinDays(db);
  if (days.isEmpty) return 0;

  final sorted = days.toList()..sort();
  var best = 1;
  var current = 1;
  for (var i = 1; i < sorted.length; i++) {
    final gap = sorted[i].difference(sorted[i - 1]).inDays;
    current = gap == 1 ? current + 1 : 1;
    if (current > best) best = current;
  }
  return best;
}

/// Which days in the current Sunday-start calendar week (through
/// today) were checked in -- powers the streak card's week strip, which
/// renders Sunday first per the user's explicit request (so this
/// counts weekday 7 as day 0 of the week, not weekday 1). Never
/// contains a day after today, same reasoning as the old
/// loadReadingDaysThisWeek this replaces: a day that hasn't happened
/// yet can't have been checked in.
Future<Set<DateTime>> loadStreakDaysThisWeek(UserDatabase db) async {
  final days = await _allCheckinDays(db);
  final today = _today();
  final weekStart = today.subtract(Duration(days: today.weekday % 7));
  return days.where((d) => !d.isBefore(weekStart) && !d.isAfter(today)).toSet();
}
