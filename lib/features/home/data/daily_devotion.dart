import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/user_database.dart';
import '../../../core/env.dart';

class DailyDevotion {
  final String title;
  final int bookId;
  final String bookName;
  final int chapter;
  final int verseStart;
  final int? verseEnd;
  final String body;
  final DateTime scheduledFor;

  const DailyDevotion({
    required this.title,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verseStart,
    required this.verseEnd,
    required this.body,
    required this.scheduledFor,
  });
}

/// Same "today, or the most recent scheduled entry on or before today"
/// logic as loadActiveWordOfDay -- see its doc comment. [bookNames]
/// comes from the same bookNamesMapProvider every other card on Home
/// already uses, not a separate lookup.
Future<DailyDevotion?> loadActiveDailyDevotion(
  UserDatabase db,
  Map<int, String> bookNames, {
  DateTime? now,
}) async {
  final today = _dateOnly(now ?? DateTime.now());
  final rows = await (db.select(db.dailyDevotionEntries)..orderBy([(t) => OrderingTerm.desc(t.scheduledFor)])).get();

  for (final row in rows) {
    if (!row.scheduledFor.isAfter(today)) {
      return DailyDevotion(
        title: row.title,
        bookId: row.bookId,
        bookName: bookNames[row.bookId] ?? '',
        chapter: row.chapter,
        verseStart: row.verseStart,
        verseEnd: row.verseEnd,
        body: row.body,
        scheduledFor: row.scheduledFor,
      );
    }
  }
  return null;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Best-effort, silent-fail sync of content.daily_devotions -- same
/// shape as syncWordOfDayEntries / syncDailyVerseReferences. Not gated
/// on sign-in or Premium, same reasoning as Word of the Day.
Future<void> syncDailyDevotionEntries(UserDatabase db) async {
  if (!Env.hasSupabase) return;
  try {
    final rows = await Supabase.instance.client.schema('content').from('daily_devotions').select();
    if (rows.isEmpty) return;

    await db.transaction(() async {
      await db.delete(db.dailyDevotionEntries).go();
      for (final row in rows) {
        await db.into(db.dailyDevotionEntries).insert(
              DailyDevotionEntriesCompanion.insert(
                title: row['title'] as String,
                bookId: row['book_id'] as int,
                chapter: row['chapter'] as int,
                verseStart: row['verse_start'] as int,
                verseEnd: Value(row['verse_end'] as int?),
                body: row['body'] as String,
                scheduledFor: DateTime.parse(row['scheduled_for'] as String),
              ),
            );
      }
    });
  } catch (_) {
    // Swallowed deliberately -- see syncWordOfDayEntries' doc comment.
  }
}
