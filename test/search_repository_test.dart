import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/bible_database.dart';
import 'package:mizo_bible/features/search/data/search_repository.dart';

void main() {
  late BibleDatabase db;

  setUp(() {
    db = BibleDatabase(NativeDatabase(File('test/fixtures/bible_test.db')));
  });

  tearDown(() => db.close());

  test('finds the English match for an English query', () async {
    final results = await searchVerses(db, 'beginning');
    expect(results, hasLength(1));
    expect(results.single.translationId, 'kjv_nkjv_blend');
    expect(results.single.chapter, 1);
    expect(results.single.verse, 1);
  });

  test('matches across Mizo diacritics regardless of case', () async {
    // The stored word is "Pathianin" -- querying with different case and
    // no attempt at diacritics still has to find it via text_folded.
    final results = await searchVerses(db, 'PATHIANIN');
    expect(results, isNotEmpty);
    expect(results.every((r) => r.translationId == 'mizo_crc_2026'), isTrue);
  });

  test('multi-word query ANDs across the folded tokens', () async {
    final results = await searchVerses(db, 'beginning God created');
    expect(results, hasLength(1));
    expect(results.single.text, contains('In the beginning'));
  });

  test('prefix matching finds a partially-typed word', () async {
    final results = await searchVerses(db, 'begin');
    expect(results, hasLength(1));
  });

  test('empty query returns no results without querying', () async {
    expect(await searchVerses(db, ''), isEmpty);
    expect(await searchVerses(db, '   '), isEmpty);
  });

  test('a query with FTS5 special characters does not throw', () async {
    // Would be a syntax error unquoted (AND/OR/NOT/- are FTS5 operators).
    await expectLater(searchVerses(db, 'light" OR "darkness -test'), completes);
  });
}
