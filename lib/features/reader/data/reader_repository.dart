import 'package:drift/drift.dart';

import '../../../core/db/bible_database.dart';
import '../domain/reader_item.dart';

/// Which translation renders on which side. A UI setting (swap sides /
/// single-language mode), not a content fact -- see parallel_rows' own
/// a/b comment in bible_database.dart.
class ReaderSides {
  final String aTranslationId;
  final String bTranslationId;
  const ReaderSides({required this.aTranslationId, required this.bTranslationId});

  String get pairId => '$aTranslationId|$bTranslationId';
}

const defaultReaderSides = ReaderSides(
  aTranslationId: 'mizo_crc_2026',
  bTranslationId: 'kjv_nkjv_blend',
);

/// Loads one whole book's worth of [ReaderItem]s, eagerly -- per the plan,
/// even Psalms (the largest book) is small enough that windowed lazy
/// loading isn't worth the complexity.
Future<List<ReaderItem>> loadBookReaderItems(
  BibleDatabase db,
  int bookId, {
  ReaderSides sides = defaultReaderSides,
}) async {
  final rows = await (db.select(db.parallelRows)
        ..where((r) => r.bookId.equals(bookId) & r.pairId.equals(sides.pairId))
        ..orderBy([(r) => OrderingTerm.asc(r.chapter), (r) => OrderingTerm.asc(r.rowIndex)]))
      .get();

  final verseRows = await (db.select(db.verses)..where((v) => v.bookId.equals(bookId))).get();
  final aVerses = <(int, int), Verse>{};
  final bVerses = <(int, int), Verse>{};
  for (final v in verseRows) {
    if (v.translationId == sides.aTranslationId) aVerses[(v.chapter, v.verse)] = v;
    if (v.translationId == sides.bTranslationId) bVerses[(v.chapter, v.verse)] = v;
  }

  String? joinText(Map<(int, int), Verse> verses, int chapter, int? start, int? end) {
    if (start == null || end == null) return null;
    final parts = [
      for (var verse = start; verse <= end; verse++) verses[(chapter, verse)]?.verseText,
    ].whereType<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }

  final items = <ReaderItem>[];
  int? currentChapter;

  for (final row in rows) {
    if (row.chapter != currentChapter) {
      items.add(ChapterHeader(row.chapter));
      currentChapter = row.chapter;
    }

    final aHeading = row.aStart == null ? null : aVerses[(row.chapter, row.aStart)]?.heading;
    final bHeading = row.bStart == null ? null : bVerses[(row.chapter, row.bStart)]?.heading;
    if (aHeading != null || bHeading != null) {
      items.add(SectionHeading(
        chapter: row.chapter,
        verse: row.aStart ?? row.bStart!,
        a: aHeading,
        b: bHeading,
      ));
    }

    items.add(VerseRow(
      chapter: row.chapter,
      label: row.label,
      a: joinText(aVerses, row.chapter, row.aStart, row.aEnd),
      b: joinText(bVerses, row.chapter, row.bStart, row.bEnd),
    ));
  }

  return items;
}
