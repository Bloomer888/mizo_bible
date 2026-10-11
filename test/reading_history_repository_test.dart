import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/reader/data/reading_history_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('empty history loads as an empty list', () async {
    expect(await loadHistory(db, const {}), isEmpty);
  });

  test('logs a visit and loads it back', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    final history = await loadHistory(db, {1: 'Genesis'});
    expect(history, hasLength(1));
    expect(history.single.bookName, 'Genesis');
    expect(history.single.chapter, 1);
  });

  test('repeating the same chapter does not flood the log', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 1);

    final rows = await db.select(db.readingHistory).get();
    expect(rows, hasLength(1));
  });

  test('visiting a different chapter logs a new entry, most recent first', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 2);

    final history = await loadHistory(db, {1: 'Genesis'});
    expect(history, hasLength(2));
    expect(history.first.chapter, 2);
  });

  test('revisiting an earlier chapter logs a fresh entry (not deduped globally)', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 2);
    await logChapterVisit(db, bookId: 1, chapter: 1);

    final rows = await db.select(db.readingHistory).get();
    expect(rows, hasLength(3));
  });

  group('loadReadingStreak', () {
    Future<void> visitOn(DateTime day) {
      return db.into(db.readingHistory).insert(
            ReadingHistoryCompanion.insert(
              id: '${day.toIso8601String()}-${day.hashCode}',
              bookId: 1,
              chapter: 1,
              createdAt: Value(day),
            ),
          );
    }

    DateTime daysAgo(int n) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - n, 12);
    }

    test('no history at all is a zero streak', () async {
      expect(await loadReadingStreak(db), 0);
    });

    test('reading only today is a 1-day streak', () async {
      await visitOn(daysAgo(0));
      expect(await loadReadingStreak(db), 1);
    });

    test('three consecutive days ending today is a 3-day streak', () async {
      await visitOn(daysAgo(2));
      await visitOn(daysAgo(1));
      await visitOn(daysAgo(0));
      expect(await loadReadingStreak(db), 3);
    });

    test('reading yesterday but not yet today still counts (grace day)', () async {
      await visitOn(daysAgo(2));
      await visitOn(daysAgo(1));
      expect(await loadReadingStreak(db), 2);
    });

    test('a gap before today breaks the streak entirely', () async {
      // Read two days ago, but neither yesterday nor today -- the most
      // recent activity is too old for the grace day to reach.
      await visitOn(daysAgo(2));
      expect(await loadReadingStreak(db), 0);
    });

    test('an older gap does not shorten a streak that is otherwise unbroken', () async {
      await visitOn(daysAgo(10));
      await visitOn(daysAgo(1));
      await visitOn(daysAgo(0));
      expect(await loadReadingStreak(db), 2);
    });

    test('multiple visits on the same day still only count once', () async {
      await visitOn(daysAgo(0));
      await visitOn(DateTime.now());
      expect(await loadReadingStreak(db), 1);
    });
  });
}
