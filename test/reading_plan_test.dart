import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/features/reading_plans/data/reading_plan.dart';

void main() {
  group('splitIntoDays', () {
    test('every chapter appears exactly once, in order, across all days', () {
      const books = <(int, int)>[(1, 3), (2, 2)]; // 5 chapters total
      final days = splitIntoDays(books, 2);

      final flattened = days.expand((d) => d).toList();
      expect(flattened, [(1, 1), (1, 2), (1, 3), (2, 1), (2, 2)]);
    });

    test('distributes a remainder across the front days, one extra chapter each', () {
      // 5 chapters over 2 days -> day 1 gets 3, day 2 gets 2.
      const books = <(int, int)>[(1, 5)];
      final days = splitIntoDays(books, 2);

      expect(days[0], hasLength(3));
      expect(days[1], hasLength(2));
    });

    test('divides evenly with no remainder when the chapter count is a multiple of the day count', () {
      const books = <(int, int)>[(1, 6)];
      final days = splitIntoDays(books, 3);

      for (final day in days) {
        expect(day, hasLength(2));
      }
    });

    test('a day can span a book boundary', () {
      // 3 + 2 chapters over 2 days -> day 1 gets 3 (all of book 1), day
      // 2 gets 2 (all of book 2) with this exact split; shift the
      // count to force a boundary mid-day instead.
      const books = <(int, int)>[(1, 2), (2, 3)]; // 5 chapters over 2 days -> 3, 2
      final days = splitIntoDays(books, 2);

      expect(days[0], [(1, 1), (1, 2), (2, 1)]);
      expect(days[1], [(2, 2), (2, 3)]);
    });

    test('no day is ever empty for a sane chapter-count-to-day-count ratio', () {
      const books = <(int, int)>[(1, 28), (2, 16)];
      final days = splitIntoDays(books, 10);

      for (final day in days) {
        expect(day, isNotEmpty);
      }
    });
  });

  group('newTestamentIn90Days', () {
    test('covers exactly 90 days', () {
      expect(newTestamentIn90Days.totalDays, 90);
      expect(newTestamentIn90Days.days, hasLength(90));
    });

    test('covers all 260 New Testament chapters with none missing or duplicated', () {
      final flattened = newTestamentIn90Days.days.expand((d) => d).toList();
      expect(flattened.length, 260);
      expect(flattened.toSet().length, 260); // no duplicates
    });

    test('starts at Matthew 1 and ends at Revelation 22', () {
      expect(newTestamentIn90Days.days.first.first, (40, 1));
      expect(newTestamentIn90Days.days.last.last, (66, 22));
    });

    test('no day is empty', () {
      for (final day in newTestamentIn90Days.days) {
        expect(day, isNotEmpty);
      }
    });
  });

  group('findReadingPlan', () {
    test('finds the New Testament plan by id', () {
      expect(findReadingPlan('nt_90_days'), isNotNull);
      expect(findReadingPlan('nt_90_days')!.name, 'New Testament in 90 Days');
    });

    test('returns null for an unknown id rather than throwing', () {
      expect(findReadingPlan('does_not_exist'), isNull);
    });
  });

  group('formatPlanDayReading', () {
    const names = {40: 'Matthew', 41: 'Mark'};

    test('a single chapter reads as just "Book N"', () {
      expect(formatPlanDayReading([(40, 1)], names), 'Matthew 1');
    });

    test('consecutive chapters in the same book collapse into a range', () {
      expect(formatPlanDayReading([(40, 1), (40, 2), (40, 3)], names), 'Matthew 1-3');
    });

    test('a book boundary starts a new part instead of extending the range', () {
      expect(formatPlanDayReading([(40, 28), (41, 1)], names), 'Matthew 28, Mark 1');
    });

    test('a gap in chapter numbers within the same book also starts a new part', () {
      // Shouldn't happen for a real generated plan day (splitIntoDays
      // never skips a chapter), but the formatter must not silently
      // merge a gap into a misleading range regardless.
      expect(formatPlanDayReading([(40, 1), (40, 3)], names), 'Matthew 1, Matthew 3');
    });

    test('an unknown book id falls back to an empty name rather than throwing', () {
      expect(formatPlanDayReading([(99, 1)], names), ' 1');
    });
  });
}
