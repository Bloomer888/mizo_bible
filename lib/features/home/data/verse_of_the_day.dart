import 'package:drift/drift.dart';

import '../../../core/db/bible_database.dart';
import '../../reader/data/reader_repository.dart' show defaultReaderSides;

/// Well-known, encouraging, single-verse-complete references -- not a
/// true random pick across the whole Bible, deliberately. A uniform
/// random verse could just as easily land on a genealogy entry or a
/// mid-sentence fragment from a legal passage, which defeats the point
/// of a "verse of the day." Every entry here was checked directly
/// against bible.db before being added (book/chapter/verse exists in
/// both translations, and the English text reads as a complete
/// thought -- a few otherwise-famous candidates were left out because
/// the source text runs a trailing section heading onto the verse,
/// e.g. Isaiah 40:31, or because the well-known quote only completes
/// across two verses, e.g. Romans 8:38).
const _curatedReferences = <(int bookId, int chapter, int verse)>[
  (1, 1, 1), (19, 23, 1), (19, 46, 1), (19, 119, 105), (20, 3, 5),
  (23, 41, 10), (24, 29, 11), (40, 5, 14), (40, 6, 33), (40, 11, 28),
  (40, 28, 20), (43, 3, 16), (43, 14, 27), (45, 8, 28), (46, 13, 4),
  (47, 5, 17), (48, 5, 22), (49, 2, 8), (50, 4, 6), (50, 4, 13),
  (50, 4, 19), (51, 3, 23), (52, 5, 16), (58, 11, 1), (58, 13, 8),
  (59, 1, 5), (60, 5, 7), (62, 4, 8), (66, 21, 4), (19, 27, 1),
  (19, 34, 8), (19, 37, 4), (19, 91, 1), (19, 100, 5), (19, 118, 24),
  (19, 139, 14), (20, 16, 3), (20, 18, 10), (23, 26, 3), (25, 3, 22),
  (36, 3, 17), (40, 7, 7), (42, 1, 37), (43, 1, 1), (43, 10, 10),
  (46, 16, 14), (48, 6, 9), (49, 3, 20), (49, 6, 10), (50, 1, 6),
  (51, 3, 2), (55, 3, 16), (58, 12, 1), (59, 1, 2), (59, 4, 8),
  (60, 5, 6), (61, 1, 3), (62, 1, 9), (65, 1, 24), (19, 56, 3),
  (19, 73, 26), (19, 126, 5), (19, 147, 3), (23, 43, 2),
]; // 64 references

/// How long one reference stays current -- 2.5 days, the user's
/// explicit choice, not a daily rotation despite the "verse of the
/// day" name staying put in the UI. Paired with a Premium notification
/// that fires right when a period boundary is crossed (see
/// scheduleVerseChangeNotification in daily_verse_notifications.dart).
const verseRotationPeriod = Duration(hours: 60);

/// Which 60-hour period [instant] falls in, counted from the Unix
/// epoch (not "day of year") -- a fixed, globally-shared grid every
/// user's device agrees on regardless of timezone or calendar year, so
/// "verse of the day" still means everyone sees the same one at the
/// same real-world moment, the way the old day-based version did.
int _periodIndexFor(DateTime instant) {
  return instant.toUtc().difference(DateTime.utc(1970)).inHours ~/ verseRotationPeriod.inHours;
}

/// Deterministic, not random: the same 60-hour period always picks the
/// same reference, for every user on every device.
(int bookId, int chapter, int verse) verseReferenceForInstant(DateTime instant) {
  return _curatedReferences[_periodIndexFor(instant) % _curatedReferences.length];
}

/// The exact instant the period containing [instant] began.
DateTime periodStartFor(DateTime instant) {
  return DateTime.utc(1970).add(verseRotationPeriod * _periodIndexFor(instant));
}

/// The exact instant the *next* period (and so the next reference)
/// begins -- what the Premium "verse changed" notification schedules
/// against.
DateTime nextRotationAfter(DateTime instant) {
  return periodStartFor(instant).add(verseRotationPeriod);
}

class VerseOfTheDay {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String mizoText;
  final String englishText;

  const VerseOfTheDay({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.mizoText,
    required this.englishText,
  });
}

/// Null only if the curated reference somehow isn't in this build's
/// bible.db -- shouldn't happen (every entry was checked against the
/// real database before being added above), but a missing verse must
/// never crash the Home tab, so this degrades to "don't show the
/// card" rather than throwing.
Future<VerseOfTheDay?> loadVerseOfTheDay(
  BibleDatabase db,
  Map<int, String> bookNames, {
  DateTime? now,
}) async {
  final (bookId, chapter, verse) = verseReferenceForInstant(now ?? DateTime.now());

  final rows = await (db.select(db.verses)
        ..where((v) => v.bookId.equals(bookId) & v.chapter.equals(chapter) & v.verse.equals(verse)))
      .get();

  String? mizoText;
  String? englishText;
  for (final row in rows) {
    if (row.translationId == defaultReaderSides.aTranslationId) mizoText = row.verseText;
    if (row.translationId == defaultReaderSides.bTranslationId) englishText = row.verseText;
  }
  if (mizoText == null || englishText == null) return null;

  return VerseOfTheDay(
    bookId: bookId,
    bookName: bookNames[bookId] ?? '',
    chapter: chapter,
    verse: verse,
    mizoText: mizoText,
    englishText: englishText,
  );
}
