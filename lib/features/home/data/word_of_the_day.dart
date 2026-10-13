import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/user_database.dart';
import '../../../core/env.dart';

class WordOfTheDay {
  final String word;
  final String meaning;
  final DateTime scheduledFor;

  const WordOfTheDay({
    required this.word,
    required this.meaning,
    required this.scheduledFor,
  });
}

/// The locally-cached entry whose scheduledFor is today or the most
/// recent date on or before today -- so a day the admin hasn't filled
/// in yet still shows yesterday's (or whichever was last scheduled)
/// rather than nothing, and a device that's been offline for a few
/// days catches up to the latest one once it resyncs. Null if the
/// cache is empty (nothing synced yet, or the admin hasn't added
/// anything) -- the Home card hides itself in that case rather than
/// showing a placeholder.
Future<WordOfTheDay?> loadActiveWordOfDay(UserDatabase db, {DateTime? now}) async {
  final today = _dateOnly(now ?? DateTime.now());
  final rows = await (db.select(db.wordOfDayEntries)..orderBy([(t) => OrderingTerm.desc(t.scheduledFor)])).get();

  for (final row in rows) {
    if (!row.scheduledFor.isAfter(today)) {
      return WordOfTheDay(word: row.word, meaning: row.meaning, scheduledFor: row.scheduledFor);
    }
  }
  return null;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Best-effort, silent-fail: fetches content.word_of_day from Supabase
/// and replaces the local cache wholesale -- same shape as
/// syncDailyVerseReferences in verse_of_the_day.dart. Not gated on
/// sign-in or Premium: Word of the Day is a free feature, and the
/// table is readable by anyone via the publishable key (the same
/// narrow, explicit exception content.daily_verses already uses).
Future<void> syncWordOfDayEntries(UserDatabase db) async {
  if (!Env.hasSupabase) return;
  try {
    final rows = await Supabase.instance.client.schema('content').from('word_of_day').select();
    if (rows.isEmpty) return;

    await db.transaction(() async {
      await db.delete(db.wordOfDayEntries).go();
      for (final row in rows) {
        await db.into(db.wordOfDayEntries).insert(
              WordOfDayEntriesCompanion.insert(
                word: row['word'] as String,
                meaning: row['meaning'] as String,
                scheduledFor: DateTime.parse(row['scheduled_for'] as String),
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
