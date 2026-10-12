/// A plan is just a name/description plus a pre-split day-by-day
/// chapter sequence -- no runtime content pipeline, no admin panel,
/// same "hand-curated, checked once" spirit as the Verse of the Day
/// list. Adding a plan later means adding another top-level constant
/// to [availableReadingPlans], not touching any of the surrounding
/// feature code.
class ReadingPlan {
  final String id;
  final String name;
  final String description;
  final int totalDays;

  /// days[i] is the list of (bookId, chapter) to read on day i + 1.
  /// A day can span two books near a book boundary -- that's expected,
  /// not a bug, since chapters are distributed evenly by count, not
  /// aligned to book starts.
  final List<List<(int bookId, int chapter)>> days;

  const ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.totalDays,
    required this.days,
  });
}

// New Testament book IDs (40-66) and their chapter counts, in
// canonical order -- verified directly against assets/db/bible.db's
// books table before being hardcoded here, not assumed from memory.
const _newTestamentChapterCounts = <(int bookId, int chapterCount)>[
  (40, 28), (41, 16), (42, 24), (43, 21), (44, 28), (45, 16), (46, 16),
  (47, 13), (48, 6), (49, 6), (50, 4), (51, 4), (52, 5), (53, 3),
  (54, 6), (55, 4), (56, 3), (57, 1), (58, 13), (59, 5), (60, 5),
  (61, 3), (62, 5), (63, 1), (64, 1), (65, 1), (66, 22),
];

/// Flattens a book/chapter-count list into one chapter-by-chapter
/// sequence in canonical order, then splits it into [totalDays]
/// buckets as evenly as possible. The chapter total doesn't divide
/// evenly by the day count in general (260 NT chapters / 90 days),
/// so the first `chapters.length % totalDays` days get one extra
/// chapter and the rest get the plain floor -- correct-by-construction
/// (every chapter appears exactly once, in order) rather than a
/// hand-typed table that could silently skip or repeat one.
List<List<(int bookId, int chapter)>> splitIntoDays(
  List<(int bookId, int chapterCount)> books,
  int totalDays,
) {
  final flat = <(int, int)>[
    for (final (bookId, chapterCount) in books)
      for (var c = 1; c <= chapterCount; c++) (bookId, c),
  ];

  final base = flat.length ~/ totalDays;
  final remainder = flat.length % totalDays;

  final result = <List<(int, int)>>[];
  var index = 0;
  for (var day = 0; day < totalDays; day++) {
    final count = base + (day < remainder ? 1 : 0);
    result.add(flat.sublist(index, index + count));
    index += count;
  }
  return result;
}

final newTestamentIn90Days = ReadingPlan(
  id: 'nt_90_days',
  name: 'New Testament in 90 Days',
  description: 'Read through the entire New Testament at a steady, manageable pace -- about three chapters a day.',
  totalDays: 90,
  days: splitIntoDays(_newTestamentChapterCounts, 90),
);

/// Just the one plan for now, deliberately -- launch with a single
/// plan and add more based on real usage, same "ship lean" pattern as
/// Premium itself. A list from day one so adding a second plan later
/// means appending an entry, not a refactor.
final allReadingPlans = <ReadingPlan>[newTestamentIn90Days];

ReadingPlan? findReadingPlan(String id) {
  for (final plan in allReadingPlans) {
    if (plan.id == id) return plan;
  }
  return null;
}

/// Groups a day's (bookId, chapter) list into human-readable ranges --
/// "Matthew 1-3" rather than "Matthew 1, Matthew 2, Matthew 3", and
/// "Matthew 28, Mark 1" (no range) across a book boundary. [bookNames]
/// comes from the same bookNamesMapProvider every other card on Home
/// already uses, not a separate lookup.
String formatPlanDayReading(List<(int bookId, int chapter)> readings, Map<int, String> bookNames) {
  final parts = <String>[];
  var i = 0;
  while (i < readings.length) {
    final (bookId, startChapter) = readings[i];
    var endChapter = startChapter;
    var j = i + 1;
    while (j < readings.length && readings[j].$1 == bookId && readings[j].$2 == endChapter + 1) {
      endChapter = readings[j].$2;
      j++;
    }
    final name = bookNames[bookId] ?? '';
    parts.add(startChapter == endChapter ? '$name $startChapter' : '$name $startChapter-$endChapter');
    i = j;
  }
  return parts.join(', ');
}
