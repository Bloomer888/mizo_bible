import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/home/data/word_of_the_day.dart';

void main() {
  group('loadActiveWordOfDay', () {
    late UserDatabase db;

    setUp(() => db = UserDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('returns null when the cache is empty -- no entry yet, not a crash', () async {
      final result = await loadActiveWordOfDay(db, now: DateTime(2026, 1, 1));
      expect(result, isNull);
    });

    test('returns the entry scheduled for today', () async {
      await db.into(db.wordOfDayEntries).insert(
            WordOfDayEntriesCompanion.insert(word: 'Grace', meaning: 'Unmerited favor.', scheduledFor: DateTime(2026, 1, 1)),
          );

      final result = await loadActiveWordOfDay(db, now: DateTime(2026, 1, 1));
      expect(result, isNotNull);
      expect(result!.word, 'Grace');
      expect(result.meaning, 'Unmerited favor.');
    });

    test('falls back to the most recent past entry when nothing is scheduled for today', () async {
      await db.into(db.wordOfDayEntries).insert(
            WordOfDayEntriesCompanion.insert(word: 'Faith', meaning: 'Trust.', scheduledFor: DateTime(2026, 1, 1)),
          );

      final result = await loadActiveWordOfDay(db, now: DateTime(2026, 1, 5));
      expect(result!.word, 'Faith');
    });

    test('never returns a future-scheduled entry early', () async {
      await db.into(db.wordOfDayEntries).insert(
            WordOfDayEntriesCompanion.insert(word: 'Hope', meaning: 'Future.', scheduledFor: DateTime(2026, 1, 10)),
          );

      final result = await loadActiveWordOfDay(db, now: DateTime(2026, 1, 1));
      expect(result, isNull);
    });

    test('picks the latest entry that is not in the future, among several', () async {
      await db.into(db.wordOfDayEntries).insert(
            WordOfDayEntriesCompanion.insert(word: 'Old', meaning: '...', scheduledFor: DateTime(2026, 1, 1)),
          );
      await db.into(db.wordOfDayEntries).insert(
            WordOfDayEntriesCompanion.insert(word: 'Current', meaning: '...', scheduledFor: DateTime(2026, 1, 5)),
          );
      await db.into(db.wordOfDayEntries).insert(
            WordOfDayEntriesCompanion.insert(word: 'Future', meaning: '...', scheduledFor: DateTime(2026, 1, 20)),
          );

      final result = await loadActiveWordOfDay(db, now: DateTime(2026, 1, 10));
      expect(result!.word, 'Current');
    });
  });
}
