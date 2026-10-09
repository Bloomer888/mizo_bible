import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'bible_database.g.dart';

/// The 66 canonical books' metadata. Translation-independent -- mirrors
/// content.books (supabase/migrations/20261008133644_content_schema.sql).
class Books extends Table {
  IntColumn get id => integer()();
  TextColumn get testament => text()();
  IntColumn get chapterCount => integer().named('chapter_count')();
  TextColumn get osisCode => text().named('osis_code')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors content.translations, minus admin-only edit-log concerns.
class Translations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get shortName => text().named('short_name')();
  TextColumn get languageCode => text().named('language_code')();
  IntColumn get year => integer().nullable()();
  TextColumn get publisher => text().nullable()();
  TextColumn get rightsStatus => text().named('rights_status')();
  TextColumn get rightsNotes => text().named('rights_notes').nullable()();
  TextColumn get licenseText => text().named('license_text').nullable()();
  IntColumn get sortOrder => integer().named('sort_order')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-translation book names, e.g. 'Genesis' vs its Mizo equivalent.
class BookNames extends Table {
  IntColumn get bookId => integer().named('book_id').references(Books, #id)();
  TextColumn get translationId =>
      text().named('translation_id').references(Translations, #id)();
  TextColumn get name => text()();
  TextColumn get shortName => text().named('short_name')();

  @override
  Set<Column> get primaryKey => {bookId, translationId};
}

/// The verse text itself. `textFolded` is pre-computed by
/// tool/export_bible_db.py at build time via the same fold_for_search rules
/// as lib/core/text/fold.dart -- fold the user's search query with that, not
/// with a fresh case-insensitive LIKE on `verseText`, or accents will break
/// matching.
class Verses extends Table {
  TextColumn get translationId =>
      text().named('translation_id').references(Translations, #id)();
  IntColumn get bookId => integer().named('book_id').references(Books, #id)();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  // Named verseText, not text -- `text` would shadow Table's own text()
  // column-builder method.
  TextColumn get verseText => text().named('text')();
  TextColumn get textFolded => text().named('text_folded')();
  TextColumn get heading => text().nullable()();
  TextColumn get crossRef => text().named('cross_ref').nullable()();

  @override
  Set<Column> get primaryKey => {translationId, bookId, chapter, verse};
}

/// Verse-alignment between one pair of translations, precomputed so the
/// reader never has to guess how to line up two differently-versified
/// columns at render time. a/b, not left/right -- which side a translation
/// displays on is a UI setting, not a content fact.
class ParallelRows extends Table {
  TextColumn get pairId => text().named('pair_id')();
  IntColumn get bookId => integer().named('book_id').references(Books, #id)();
  IntColumn get chapter => integer()();
  IntColumn get rowIndex => integer().named('row_index')();
  TextColumn get label => text()();
  IntColumn get aStart => integer().named('a_start').nullable()();
  IntColumn get aEnd => integer().named('a_end').nullable()();
  IntColumn get bStart => integer().named('b_start').nullable()();
  IntColumn get bEnd => integer().named('b_end').nullable()();

  @override
  Set<Column> get primaryKey => {pairId, bookId, chapter, rowIndex};
}

/// Read-only handle onto the bundled, pre-populated Bible content --
/// built by tool/export_bible_db.py from Supabase, never written to by the
/// app itself. User data (bookmarks, notes, ...) lives in a separate
/// UserDatabase/user.db so an app update that replaces this file can never
/// touch anything the reader has saved.
@DriftDatabase(tables: [Translations, Books, BookNames, Verses, ParallelRows])
class BibleDatabase extends _$BibleDatabase {
  BibleDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // export_bible_db.py stamps PRAGMA user_version = 1 on the file it
  // builds. Matching that here (rather than leaving Drift's default of 0)
  // is what tells Drift on open "this schema already exists, don't run
  // onCreate" -- otherwise it would try to CREATE TABLE against a file
  // whose tables already exist and fail. The two sides must agree, same
  // reasoning as lib/core/text/fold.dart needing to match tool/fold.py.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // Only reachable if bible.db is ever opened before the asset-copy
        // step below has run, which shouldn't happen in normal use --
        // kept as a safe fallback rather than assuming it's unreachable.
        onCreate: (m) => m.createAll(),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'bible.db'));

    if (!await dbFile.exists()) {
      final asset = await rootBundle.load('assets/db/bible.db');
      final bytes = asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes);
      await dbFile.writeAsBytes(bytes, flush: true);
    }

    return NativeDatabase.createInBackground(dbFile);
  });
}
