import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/bible_database.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/home/data/verse_of_the_day.dart';

void main() {
  // The Unix epoch is period index 0 by construction (see
  // verseReferenceForInstant's doc comment) -- a clean, reproducible
  // anchor for these tests rather than depending on today's real date.
  final epoch = DateTime.utc(1970);

  group('verseReferenceForInstant', () {
    test('is deterministic -- the same instant always picks the same reference', () {
      final instant = DateTime.utc(2026, 3, 15);
      expect(verseReferenceForInstant(instant), verseReferenceForInstant(instant));
    });

    test('the Unix epoch picks the first reference in the list (Genesis 1:1)', () {
      expect(verseReferenceForInstant(epoch), (1, 1, 1));
    });

    test('two instants in the same 60-hour period pick the same reference', () {
      final start = verseReferenceForInstant(epoch);
      final almostThere = verseReferenceForInstant(epoch.add(const Duration(hours: 59, minutes: 59)));
      expect(almostThere, start);
    });

    test('crossing a period boundary picks a different reference', () {
      final before = verseReferenceForInstant(epoch.add(const Duration(hours: 59, minutes: 59)));
      final after = verseReferenceForInstant(epoch.add(const Duration(hours: 60)));
      expect(after, isNot(before));
    });

    test('wraps around rather than going out of range past the curated list length', () {
      // 70 periods comfortably passes the 64-entry list length, so this
      // exercises the wrap without hardcoding the list's exact size.
      for (var p = 0; p < 70; p++) {
        final (bookId, chapter, verse) = verseReferenceForInstant(epoch.add(verseRotationPeriod * p));
        expect(bookId, greaterThan(0));
        expect(chapter, greaterThan(0));
        expect(verse, greaterThan(0));
      }
    });

    test('the period index wraps back to the same reference after a full cycle', () {
      // 64 periods later lands back on index 0 in a 64-entry list.
      expect(verseReferenceForInstant(epoch.add(verseRotationPeriod * 64)), verseReferenceForInstant(epoch));
    });

    test('an explicit references list overrides the hardcoded default', () {
      // Proves the admin-editable path actually changes the result,
      // not just that a parameter exists -- a single-entry list always
      // picks that one entry regardless of period.
      const custom = <(int, int, int)>[(40, 1, 1)];
      expect(verseReferenceForInstant(epoch, references: custom), (40, 1, 1));
      expect(verseReferenceForInstant(epoch.add(verseRotationPeriod * 5), references: custom), (40, 1, 1));
    });
  });

  group('periodStartFor / nextRotationAfter', () {
    test('periodStartFor returns the exact period start unchanged', () {
      expect(periodStartFor(epoch), epoch);
    });

    test('periodStartFor rounds an instant mid-period down to that period\'s start', () {
      final midPeriod = epoch.add(const Duration(hours: 30));
      expect(periodStartFor(midPeriod), epoch);
    });

    test('nextRotationAfter is exactly one period after the current period\'s start', () {
      final midPeriod = epoch.add(const Duration(hours: 30));
      expect(nextRotationAfter(midPeriod), epoch.add(verseRotationPeriod));
    });

    test('the instant returned by nextRotationAfter is in a different period than the original', () {
      final now = epoch.add(const Duration(hours: 10));
      final next = nextRotationAfter(now);
      expect(verseReferenceForInstant(next), isNot(verseReferenceForInstant(now)));
    });
  });

  group('loadVerseOfTheDay', () {
    late BibleDatabase db;

    setUp(() => db = BibleDatabase(NativeDatabase(File('test/fixtures/bible_test.db'))));
    tearDown(() => db.close());

    test('loads the real verse text for a reference present in the database', () async {
      // The Unix epoch maps to (1, 1, 1) -- Genesis 1:1, which the small
      // test fixture actually contains (see bible_database_test.dart).
      final result = await loadVerseOfTheDay(db, {1: 'Genesis'}, now: epoch);

      expect(result, isNotNull);
      expect(result!.bookName, 'Genesis');
      expect(result.chapter, 1);
      expect(result.verse, 1);
      expect(result.englishText, 'In the beginning God created the heavens and the earth.');
      expect(result.mizoText, 'A tîrah Pathianin lei leh vânte a siam a.');
    });

    test('returns null rather than throwing when the reference is not in this database', () async {
      // One period after the epoch maps to the second curated
      // reference (Psalm 23:1), which the Genesis-only test fixture
      // doesn't contain -- exercises the missing-verse path that a
      // real build should never hit, but must still degrade safely
      // from if it somehow did.
      final result = await loadVerseOfTheDay(db, {1: 'Genesis'}, now: DateTime.utc(1970).add(verseRotationPeriod));
      expect(result, isNull);
    });
  });

  group('loadActiveDailyVerseReferences', () {
    late UserDatabase userDb;

    setUp(() => userDb = UserDatabase(NativeDatabase.memory()));
    tearDown(() => userDb.close());

    test('falls back to the hardcoded default list when the cache is empty', () async {
      // Covers both a fresh install and a device that's never reached
      // syncDailyVerseReferences successfully -- the feature must still
      // show something, not nothing. Checks against verseReferenceForInstant's
      // own default (same list, exercised via the Unix epoch anchor
      // already used throughout this file) rather than re-importing the
      // private _defaultReferences constant.
      final result = await loadActiveDailyVerseReferences(userDb);
      expect(result, isNotEmpty);
      expect(result[0], verseReferenceForInstant(epoch));
    });

    test('returns the cached references, ordered by sortOrder, once the cache is populated', () async {
      await userDb.into(userDb.dailyVerseRefs).insert(
            DailyVerseRefsCompanion.insert(bookId: 43, chapter: 3, verse: 16, sortOrder: 1),
          );
      await userDb.into(userDb.dailyVerseRefs).insert(
            DailyVerseRefsCompanion.insert(bookId: 1, chapter: 1, verse: 1, sortOrder: 0),
          );

      final result = await loadActiveDailyVerseReferences(userDb);

      expect(result, [(1, 1, 1), (43, 3, 16)]);
    });
  });
}
