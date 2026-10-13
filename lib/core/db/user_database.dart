import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'user_database.g.dart';

/// Shared by every user-data table: a client-generated UUID (not an
/// autoincrement int) so a row created offline never collides with one
/// from another device once accounts/sync exist; userId nullable because
/// rows are created before any sign-in and get stamped with a real
/// userId only at that point (see the plan's Phase 9 notes); deleted is
/// a tombstone rather than a real delete so a sync pass has something to
/// propagate; dirty marks a row not yet pushed to Supabase. None of the
/// sync machinery itself exists yet (Phase 8) -- this phase is the local
/// schema it will eventually sync through.
mixin SyncableColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

/// A saved verse reference for quick return. bookId/chapter/verse
/// reference content.verses' own identity (book id, chapter, verse) --
/// not a foreign key, since this database has no access to bible.db's
/// tables (two separate files, deliberately -- see this file's own doc
/// comment on BibleDatabase for why).
class Bookmarks extends Table with SyncableColumns {
  IntColumn get bookId => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A highlighted verse. color is a plain string (e.g. a palette key like
/// 'yellow') rather than a packed ARGB int, so the available colors can
/// change later without a migration touching stored data.
class Highlights extends Table with SyncableColumns {
  IntColumn get bookId => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get color => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A free-text note attached to one verse. Named content, not text --
/// text would shadow Table's own text() column-builder method (the same
/// gotcha already hit once in bible_database.dart's Verses table).
class Notes extends Table with SyncableColumns {
  IntColumn get bookId => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// An append-only log of chapters visited, oldest and newest both
/// derivable from createdAt -- a "recently read" feature reads this
/// table, nothing writes a running summary anywhere else.
class ReadingHistory extends Table with SyncableColumns {
  IntColumn get bookId => integer()();
  IntColumn get chapter => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per book: the last position reached, so reopening a book
/// lands back where the reader left off (the plan's Phase 5 acceptance
/// item deferred when reader_settings.dart was first built). Despite
/// being "current state" rather than a log, it still gets a UUID like
/// every other table here rather than keying on bookId directly --
/// consistent, mergeable rows matter more than a natural key this phase
/// doesn't yet need. No DB-level uniqueness on bookId yet either: with
/// userId nullable, a unique index wouldn't actually enforce "one row
/// per book" pre-login (SQL NULLs never compare equal), so
/// upsertReadingProgress does find-or-update itself instead -- the real
/// per-user constraint belongs with Phase 8's sync design, not invented
/// early against a problem that isn't here yet.
class ReadingProgress extends Table with SyncableColumns {
  IntColumn get bookId => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key-value store for user preferences -- e.g. reader_settings.dart's
/// ReaderSettings, previously in-memory only pending exactly this table.
class Settings extends Table with SyncableColumns {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per plan a user has ever started -- not one row per day,
/// which would mean a 90-row insert burst just to begin a plan.
/// completedDaysCsv is a comma-separated list of completed day numbers
/// (e.g. "1,2,3,7") rather than a separate junction table: progress is
/// always read and written as a whole for the active plan, never
/// queried day-by-day, so there's no join this would ever need to
/// support. Unlike reading_history, this table's rows *do* sync for
/// Premium members -- "pick up your plan on another device" is the
/// kind of thing sync exists for, not a privacy concern the way
/// reading history was (see reading_plan_progress_repository.dart and
/// [[project-premium-decisions]] in memory for that distinction).
class ReadingPlanProgress extends Table with SyncableColumns {
  TextColumn get planId => text().named('plan_id')();
  DateTimeColumn get startedAt => dateTime().named('started_at').withDefault(currentDateAndTime)();
  TextColumn get completedDaysCsv => text().named('completed_days_csv').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per calendar day the user manually marked as "read today" --
/// an explicit daily action (like a habit tracker's check-in), replacing
/// the old streak's passive derivation from reading_history (any chapter
/// visit counted, which also meant the streak card vanished the moment
/// it hit zero instead of ever inviting the user to start one). day is
/// normalized to local midnight. No DB-level uniqueness on day, same
/// reasoning as ReadingProgress above -- checkInToday does find-or-skip
/// itself.
class StreakCheckins extends Table with SyncableColumns {
  DateTimeColumn get day => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A local cache of Supabase's content.daily_verses -- not a
/// SyncableColumns table, since this isn't user-owned data that syncs
/// per-user, it's a shared admin-curated list the app pulls down
/// read-only (see syncDailyVerseReferences in verse_of_the_day.dart).
/// Replaced wholesale on every successful sync (old rows deleted, new
/// ones inserted) rather than reconciled row-by-row -- the list is small
/// and always fetched whole, so there's nothing to gain from diffing it.
class DailyVerseRefs extends Table {
  IntColumn get bookId => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {bookId, chapter, verse};
}

/// A local cache of Supabase's content.word_of_day -- same "shared
/// admin-curated list, not SyncableColumns" reasoning as DailyVerseRefs
/// above, but keyed on scheduledFor (the admin assigns one entry per
/// calendar date, never two for the same day -- enforced by a unique
/// constraint on the Supabase side too) rather than a book/chapter/verse
/// triple. Replaced wholesale on every successful sync, same as
/// DailyVerseRefs.
class WordOfDayEntries extends Table {
  TextColumn get word => text()();
  TextColumn get meaning => text()();
  DateTimeColumn get scheduledFor => dateTime()();

  @override
  Set<Column> get primaryKey => {scheduledFor};
}

/// A local cache of Supabase's content.daily_devotions -- same shape and
/// reasoning as WordOfDayEntries above. bookId/chapter/verseStart/
/// verseEnd reference content.verses' identity the same denormalized way
/// every other table here does (see this file's doc comment on
/// Bookmarks) -- verseEnd is nullable since a devotion can point at a
/// single verse rather than a range.
class DailyDevotionEntries extends Table {
  TextColumn get title => text()();
  IntColumn get bookId => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verseStart => integer()();
  IntColumn get verseEnd => integer().nullable()();
  TextColumn get body => text()();
  DateTimeColumn get scheduledFor => dateTime()();

  @override
  Set<Column> get primaryKey => {scheduledFor};
}

@DriftDatabase(
  tables: [
    Bookmarks,
    Highlights,
    Notes,
    ReadingHistory,
    ReadingProgress,
    Settings,
    ReadingPlanProgress,
    StreakCheckins,
    DailyVerseRefs,
    WordOfDayEntries,
    DailyDevotionEntries,
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(readingPlanProgress);
          }
          if (from < 3) {
            await m.createTable(streakCheckins);
          }
          if (from < 4) {
            await m.createTable(dailyVerseRefs);
          }
          if (from < 5) {
            await m.createTable(wordOfDayEntries);
            await m.createTable(dailyDevotionEntries);
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'user');
}

/// Separate from bibleDatabaseProvider (bible_database.dart) on purpose:
/// user.db and bible.db are two different files with two different
/// lifecycles -- an app update ships a new bible.db outright, but must
/// never touch user.db, which is why they were never one database to
/// begin with.
final userDatabaseProvider = Provider<UserDatabase>((ref) {
  final db = UserDatabase();
  ref.onDispose(db.close);
  return db;
});
