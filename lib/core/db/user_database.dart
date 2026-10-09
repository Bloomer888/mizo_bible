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

@DriftDatabase(tables: [Bookmarks, Highlights, Notes, ReadingHistory, ReadingProgress, Settings])
class UserDatabase extends _$UserDatabase {
  UserDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
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
