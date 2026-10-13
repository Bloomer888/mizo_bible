import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/env.dart';
import '../../reader/data/reader_repository.dart' show defaultReaderSides;

/// Well-known, encouraging, single-verse-complete references -- the
/// offline/first-launch fallback now that content.daily_verses exists as
/// the live, admin-editable source of truth (see
/// syncDailyVerseReferences/loadActiveDailyVerseReferences below). Used
/// whenever the local cache is empty: before any sync has ever
/// succeeded, or a device that's never been online. Not a true random
/// pick across the whole Bible, deliberately. A uniform random verse
/// could just as easily land on a genealogy entry or a mid-sentence
/// fragment from a legal passage, which defeats the point of a "verse of
/// the day." Every entry here was checked directly against bible.db
/// before being added (book/chapter/verse exists in both translations,
/// and the English text reads as a complete thought -- a few
/// otherwise-famous candidates were left out because the source text
/// runs a trailing section heading onto the verse, e.g. Isaiah 40:31, or
/// because the well-known quote only completes across two verses, e.g.
/// Romans 8:38).
const _defaultReferences = <(int bookId, int chapter, int verse)>[
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
/// same entry from [references], for every user on every device.
/// [references] defaults to the hardcoded fallback list, but real
/// callers pass whatever [loadActiveDailyVerseReferences] currently has
/// cached, so an admin's edit actually changes what this returns.
(int bookId, int chapter, int verse) verseReferenceForInstant(
  DateTime instant, {
  List<(int, int, int)> references = _defaultReferences,
}) {
  return references[_periodIndexFor(instant) % references.length];
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

/// Null only if the chosen reference somehow isn't in this build's
/// bible.db -- shouldn't happen for the hardcoded fallback list (every
/// entry was checked against the real database before being added
/// above), and an admin-added content.daily_verses reference is checked
/// the same way before the admin panel lets it save -- but a missing
/// verse must never crash the Home tab, so this degrades to "don't show
/// the card" rather than throwing.
Future<VerseOfTheDay?> loadVerseOfTheDay(
  BibleDatabase db,
  Map<int, String> bookNames, {
  DateTime? now,
  List<(int, int, int)> references = _defaultReferences,
}) async {
  final (bookId, chapter, verse) = verseReferenceForInstant(now ?? DateTime.now(), references: references);

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

/// Reads the locally-cached content.daily_verses rows, ordered the way
/// the admin arranged them -- falls back to [_defaultReferences] if the
/// cache is empty, so a fresh install (or a device that's never
/// reached [syncDailyVerseReferences] successfully) still shows
/// something instead of nothing.
Future<List<(int, int, int)>> loadActiveDailyVerseReferences(UserDatabase db) async {
  final rows = await (db.select(db.dailyVerseRefs)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  if (rows.isEmpty) return _defaultReferences;
  return [for (final r in rows) (r.bookId, r.chapter, r.verse)];
}

/// Best-effort, silent-fail: fetches content.daily_verses from Supabase
/// and replaces the local cache wholesale. Deliberately not gated on
/// sign-in or Premium -- Verse of the Day is a free feature, and this
/// one table is readable by anyone via the publishable key (a narrow,
/// explicit exception to content.* otherwise being service-role-only --
/// see the migration that created content.daily_verses). Safe to call
/// repeatedly, e.g. on every app launch/resume, same shape as
/// syncUserData in sync_repository.dart.
Future<void> syncDailyVerseReferences(UserDatabase db) async {
  if (!Env.hasSupabase) return;
  try {
    final rows = await Supabase.instance.client.schema('content').from('daily_verses').select();
    // An empty response could mean "the admin genuinely cleared the
    // list" or it could mean the migration hasn't been applied yet, or
    // a transient bad response -- either way, keep whatever's already
    // cached (or the hardcoded fallback) rather than wipe the feature
    // to nothing on an ambiguous signal.
    if (rows.isEmpty) return;

    await db.transaction(() async {
      await db.delete(db.dailyVerseRefs).go();
      for (final row in rows) {
        await db.into(db.dailyVerseRefs).insert(
              DailyVerseRefsCompanion.insert(
                bookId: row['book_id'] as int,
                chapter: row['chapter'] as int,
                verse: row['verse'] as int,
                sortOrder: row['sort_order'] as int,
              ),
            );
      }
    });
  } catch (_) {
    // Offline, unreachable, or the migration hasn't been applied yet --
    // keep whatever's cached locally rather than let this throw into
    // whatever called it (app launch/resume must never fail over this).
  }
}
