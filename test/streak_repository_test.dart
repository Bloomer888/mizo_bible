import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/home/data/streak_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  DateTime daysAgo(int n) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - n);
  }

  Future<void> checkInOn(DateTime day) {
    return db.into(db.streakCheckins).insert(
          StreakCheckinsCompanion.insert(id: '${day.toIso8601String()}-${day.hashCode}', day: day),
        );
  }

  group('checkInToday / isCheckedInToday', () {
    test('not checked in by default', () async {
      expect(await isCheckedInToday(db), false);
    });

    test('checking in is reflected immediately', () async {
      await checkInToday(db);
      expect(await isCheckedInToday(db), true);
    });

    test('checking in twice does not create a duplicate row', () async {
      await checkInToday(db);
      await checkInToday(db);
      final rows = await db.select(db.streakCheckins).get();
      expect(rows, hasLength(1));
    });
  });

  group('loadStreak', () {
    test('no check-ins at all is a zero streak', () async {
      expect(await loadStreak(db), 0);
    });

    test('checking in only today is a 1-day streak', () async {
      await checkInOn(daysAgo(0));
      expect(await loadStreak(db), 1);
    });

    test('three consecutive days ending today is a 3-day streak', () async {
      await checkInOn(daysAgo(2));
      await checkInOn(daysAgo(1));
      await checkInOn(daysAgo(0));
      expect(await loadStreak(db), 3);
    });

    test('checked in yesterday but not yet today still counts (grace day)', () async {
      await checkInOn(daysAgo(2));
      await checkInOn(daysAgo(1));
      expect(await loadStreak(db), 2);
    });

    test('a gap before today breaks the streak entirely', () async {
      await checkInOn(daysAgo(2));
      expect(await loadStreak(db), 0);
    });

    test('an older gap does not shorten a streak that is otherwise unbroken', () async {
      await checkInOn(daysAgo(10));
      await checkInOn(daysAgo(1));
      await checkInOn(daysAgo(0));
      expect(await loadStreak(db), 2);
    });
  });

  group('loadBestStreak', () {
    test('no check-ins at all is a zero best', () async {
      expect(await loadBestStreak(db), 0);
    });

    test('a single check-in is a best of 1', () async {
      await checkInOn(daysAgo(0));
      expect(await loadBestStreak(db), 1);
    });

    test('an older, longer run beats the current shorter one', () async {
      // 5-day run from 20..16 days ago, then a gap, then today only.
      for (final n in [20, 19, 18, 17, 16]) {
        await checkInOn(daysAgo(n));
      }
      await checkInOn(daysAgo(0));
      expect(await loadStreak(db), 1);
      expect(await loadBestStreak(db), 5);
    });

    test('the current run can itself be the best', () async {
      await checkInOn(daysAgo(2));
      await checkInOn(daysAgo(1));
      await checkInOn(daysAgo(0));
      expect(await loadBestStreak(db), 3);
    });
  });

  group('loadStreakDaysThisWeek', () {
    DateTime currentWeekStart() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return today.subtract(Duration(days: today.weekday % 7));
    }

    test('no check-ins at all is an empty set', () async {
      expect(await loadStreakDaysThisWeek(db), isEmpty);
    });

    test('a check-in today is included', () async {
      await checkInOn(daysAgo(0));
      final today = DateTime.now();
      expect(await loadStreakDaysThisWeek(db), contains(DateTime(today.year, today.month, today.day)));
    });

    test('a check-in on the first day of this week is included', () async {
      final weekStart = currentWeekStart();
      await checkInOn(weekStart);
      expect(await loadStreakDaysThisWeek(db), contains(weekStart));
    });

    test('a check-in the day before this week started is excluded', () async {
      final weekStart = currentWeekStart();
      await checkInOn(weekStart.subtract(const Duration(days: 1)));
      expect(await loadStreakDaysThisWeek(db), isEmpty);
    });
  });
}
