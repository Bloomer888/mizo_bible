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

  test('parallel_rows pairs Genesis 1:1-4 verse-for-verse on both sides', () async {
    final rows = await (db.select(db.parallelRows)
          ..where((r) => r.bookId.equals(1) & r.chapter.equals(1))
          ..orderBy([(r) => OrderingTerm.asc(r.rowIndex)]))
        .get();

    expect(rows, hasLength(4));
    for (var i = 0; i < rows.length; i++) {
      final verse = i + 1;
      expect(rows[i].label, '$verse');
      expect(rows[i].aStart, verse);
      expect(rows[i].bStart, verse);
    }
  });

  test('Genesis 1:4 keeps its ṭ (t-with-dot-below) intact', () async {
    final rows = await (db.select(db.verses)
          ..where((v) =>
              v.bookId.equals(1) &
              v.chapter.equals(1) &
              v.verse.equals(4) &
              v.translationId.equals('mizo_crc_2026')))
        .get();

    expect(rows, hasLength(1));
    expect(rows.single.verseText, contains('ṭ'));
  });

  test('Genesis 1:3 has no U+FFFD replacement character', () async {
    // Regression guard for the second embedded font subset (WinAnsi/
    // Latin-1 byte values, distinct from the main VNTTimes ASCII-
    // punctuation scheme) -- see CHAR_REMAP's second block in
    // extract_pdf.py. This exact verse is what surfaced the bug: it
    // rendered as `Pathian chuan, "<EFBFBD>ng lo awm rawh se,"` on a real
    // device before the fix, "\xca" (-> Ê) going through undecoded.
    final rows = await (db.select(db.verses)
          ..where((v) =>
              v.bookId.equals(1) &
              v.chapter.equals(1) &
              v.verse.equals(3) &
              v.translationId.equals('mizo_crc_2026')))
        .get();

    expect(rows, hasLength(1));
    expect(rows.single.verseText, isNot(contains('\u{FFFD}')));
    expect(rows.single.verseText, contains('Êng'));
  });
}
