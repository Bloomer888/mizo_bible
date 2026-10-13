import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/home/data/daily_devotion.dart';

void main() {
  group('loadActiveDailyDevotion', () {
    late UserDatabase db;
    const names = {43: 'John'};

    setUp(() => db = UserDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('returns null when the cache is empty', () async {
      final result = await loadActiveDailyDevotion(db, names, now: DateTime(2026, 1, 1));
      expect(result, isNull);
    });

    test('returns the entry scheduled for today, resolving the book name', () async {
      await db.into(db.dailyDevotionEntries).insert(
            DailyDevotionEntriesCompanion.insert(
              title: 'God So Loved',
              bookId: 43,
              chapter: 3,
              verseStart: 16,
              verseEnd: const Value(null),
              body: 'For God so loved the world...',
              scheduledFor: DateTime(2026, 1, 1),
            ),
          );

      final result = await loadActiveDailyDevotion(db, names, now: DateTime(2026, 1, 1));
      expect(result, isNotNull);
      expect(result!.title, 'God So Loved');
      expect(result.bookName, 'John');
      expect(result.verseEnd, isNull);
    });

    test('never returns a future-scheduled entry early', () async {
      await db.into(db.dailyDevotionEntries).insert(
            DailyDevotionEntriesCompanion.insert(
              title: 'Later',
              bookId: 43,
              chapter: 1,
              verseStart: 1,
              verseEnd: const Value(null),
              body: '...',
              scheduledFor: DateTime(2026, 2, 1),
            ),
          );

      final result = await loadActiveDailyDevotion(db, names, now: DateTime(2026, 1, 1));
      expect(result, isNull);
    });

    test('carries a verse range when verseEnd is set', () async {
      await db.into(db.dailyDevotionEntries).insert(
            DailyDevotionEntriesCompanion.insert(
              title: 'A Range',
              bookId: 43,
              chapter: 1,
              verseStart: 1,
              verseEnd: const Value(5),
              body: '...',
              scheduledFor: DateTime(2026, 1, 1),
            ),
          );

      final result = await loadActiveDailyDevotion(db, names, now: DateTime(2026, 1, 1));
      expect(result!.verseStart, 1);
      expect(result.verseEnd, 5);
    });
  });
}
