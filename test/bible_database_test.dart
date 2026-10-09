import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/bible_database.dart';

/// Exercises the real schema agreement between tool/export_bible_db.py and
/// BibleDatabase -- test/fixtures/bible_test.db was built by that same
/// Python code (see the generating command in this change's commit), not
/// hand-written, so a schema drift between the two sides fails here rather
/// than only showing up on a real device. This is the Phase 4 acceptance
/// check from the plan ("app opens bible.db and prints Genesis 1:1 in both
/// languages"), automated instead of eyeballed.
void main() {
  late BibleDatabase db;

  setUp(() {
    db = BibleDatabase(NativeDatabase(File('test/fixtures/bible_test.db')));
  });

  tearDown(() => db.close());

  test('Genesis 1:1 reads back correctly in both languages', () async {
    final rows = await (db.select(db.verses)
          ..where((v) => v.bookId.equals(1) & v.chapter.equals(1) & v.verse.equals(1)))
        .get();

    expect(rows, hasLength(2));

    final mizo = rows.firstWhere((r) => r.translationId == 'mizo_crc_2026');
    expect(mizo.verseText, 'A tîrah Pathianin lei leh vânte a siam a.');
    expect(mizo.heading, 'Thil siam Chanchin');
    expect(mizo.textFolded, 'a tirah pathianin lei leh vante a siam a.');

    final english = rows.firstWhere((r) => r.translationId == 'kjv_nkjv_blend');
    expect(english.verseText, 'In the beginning God created the heavens and the earth.');
    expect(english.heading, 'The History of Creation');
  });

  test('book_names resolves Genesis for both translations', () async {
    final rows = await (db.select(db.bookNames)..where((b) => b.bookId.equals(1))).get();
    final names = {for (final r in rows) r.translationId: r.name};
    expect(names['mizo_crc_2026'], 'Genesis');
    expect(names['kjv_nkjv_blend'], 'Genesis');
  });

  test('parallel_rows pairs Genesis 1:1 and 1:2 verse-for-verse on both sides', () async {
    final rows = await (db.select(db.parallelRows)
          ..where((r) => r.bookId.equals(1) & r.chapter.equals(1))
          ..orderBy([(r) => OrderingTerm.asc(r.rowIndex)]))
        .get();

    expect(rows, hasLength(2));
    expect(rows[0].label, '1');
    expect(rows[0].aStart, 1);
    expect(rows[0].bStart, 1);
    expect(rows[1].label, '2');
    expect(rows[1].aStart, 2);
    expect(rows[1].bStart, 2);
  });
}
