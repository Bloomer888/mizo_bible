import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/bible_database.dart';
import 'package:mizo_bible/features/home/data/verse_of_the_day.dart';

void main() {
  group('verseReferenceForDay', () {
    test('is deterministic -- the same day always picks the same reference', () {
      final day = DateTime(2026, 3, 15);
      expect(verseReferenceForDay(day), verseReferenceForDay(day));
    });

    test('January 1st picks the first reference in the list (Genesis 1:1)', () {
      expect(verseReferenceForDay(DateTime(2026, 1, 1)), (1, 1, 1));
    });

    test('different days of year can pick different references', () {
      final jan1 = verseReferenceForDay(DateTime(2026, 1, 1));
      final jan2 = verseReferenceForDay(DateTime(2026, 1, 2));
      expect(jan1, isNot(jan2));
    });

    test('wraps around rather than going out of range for a full year', () {
      // 366 to cover a leap year too -- every call must return a valid
      // reference, not throw a range error once the day count exceeds
      // the curated list's length.
      for (var d = 0; d < 366; d++) {
        final (bookId, chapter, verse) = verseReferenceForDay(DateTime(2026, 1, 1).add(Duration(days: d)));
        expect(bookId, greaterThan(0));
        expect(chapter, greaterThan(0));
        expect(verse, greaterThan(0));
      }
    });
  });

  group('loadVerseOfTheDay', () {
    late BibleDatabase db;

    setUp(() => db = BibleDatabase(NativeDatabase(File('test/fixtures/bible_test.db'))));
    tearDown(() => db.close());

    test('loads the real verse text for a reference present in the database', () async {
      // January 1st maps to (1, 1, 1) -- Genesis 1:1, which the small
      // test fixture actually contains (see bible_database_test.dart).
      final result = await loadVerseOfTheDay(db, {1: 'Genesis'}, now: DateTime(2026, 1, 1));

      expect(result, isNotNull);
      expect(result!.bookName, 'Genesis');
      expect(result.chapter, 1);
      expect(result.verse, 1);
      expect(result.englishText, 'In the beginning God created the heavens and the earth.');
      expect(result.mizoText, 'A tîrah Pathianin lei leh vânte a siam a.');
    });

    test('returns null rather than throwing when the reference is not in this database', () async {
      // The test fixture only has Genesis 1 -- any day whose curated
      // reference isn't Genesis 1:1 exercises the missing-verse path
      // that a real build should never hit, but must still degrade
      // safely from if it somehow did.
      final result = await loadVerseOfTheDay(db, {1: 'Genesis'}, now: DateTime(2026, 1, 3));
      expect(result, isNull);
    });
  });
}
