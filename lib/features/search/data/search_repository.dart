import 'package:drift/drift.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/text/fold.dart';

class SearchResult {
  final String translationId;
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;

  const SearchResult({
    required this.translationId,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });
}

/// Turns a folded query into an FTS5 MATCH expression: each word becomes
/// its own quoted-prefix token ("word"*), so "let there" finds "Let
/// there be light" via an implicit AND between tokens, and partially
/// typed words still match as the user keeps typing. Quoting each token
/// neutralizes FTS5's own query-syntax punctuation (AND/OR/NOT/-/: etc.)
/// in whatever the user typed, so a stray character never throws a query
/// syntax error.
String _buildFtsQuery(String folded) {
  final words = folded.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.map((w) => '"${w.replaceAll('"', '""')}"*').join(' ');
}

/// Searches both translations at once -- a bilingual reader may be
/// searching in either language, and FTS5 doesn't care which column of
/// verses.text_folded a row came from. Results are in canonical Bible
/// order, not relevance-ranked: for Scripture, "where does this appear"
/// is more useful than a relevance score.
Future<List<SearchResult>> searchVerses(BibleDatabase db, String query, {int limit = 100}) async {
  final folded = foldForSearch(query.trim());
  if (folded.isEmpty) return [];
  final ftsQuery = _buildFtsQuery(folded);

  final rows = await db
      .customSelect(
        '''
        select v.translation_id as translation_id, v.book_id as book_id, bn.name as book_name,
               v.chapter as chapter, v.verse as verse, v.text as text
        from verses_fts f
        join verses v on v.rowid = f.rowid
        join book_names bn on bn.book_id = v.book_id and bn.translation_id = v.translation_id
        where verses_fts match ?
        order by v.book_id, v.chapter, v.verse, v.translation_id
        limit ?
        ''',
        variables: [Variable.withString(ftsQuery), Variable.withInt(limit)],
        readsFrom: {db.verses, db.bookNames},
      )
      .get();

  return [
    for (final row in rows)
      SearchResult(
        translationId: row.read<String>('translation_id'),
        bookId: row.read<int>('book_id'),
        bookName: row.read<String>('book_name'),
        chapter: row.read<int>('chapter'),
        verse: row.read<int>('verse'),
        text: row.read<String>('text'),
      ),
  ];
}
