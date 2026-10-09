import 'package:drift/drift.dart';

import '../../../core/db/bible_database.dart';

/// English book names drive the navigation UI (book list, chapter jump,
/// app bar titles) -- the app's chrome is English throughout (see the
/// plan's "UI language" decision), separate from the reader content
/// itself, which always shows both translations side by side regardless.
const navigationTranslationId = 'kjv_nkjv_blend';

class BookInfo {
  final int id;
  final String testament;
  final int chapterCount;
  final String name;
  const BookInfo({
    required this.id,
    required this.testament,
    required this.chapterCount,
    required this.name,
  });
}

Future<List<BookInfo>> loadAllBooks(BibleDatabase db) async {
  final books = await (db.select(db.books)..orderBy([(b) => OrderingTerm.asc(b.id)])).get();
  final names = await (db.select(db.bookNames)
        ..where((n) => n.translationId.equals(navigationTranslationId)))
      .get();
  final nameById = {for (final n in names) n.bookId: n.name};

  return [
    for (final b in books)
      BookInfo(
        id: b.id,
        testament: b.testament,
        chapterCount: b.chapterCount,
        name: nameById[b.id] ?? '?',
      ),
  ];
}

Future<BookInfo> loadBookInfo(BibleDatabase db, int bookId) async {
  final book = await (db.select(db.books)..where((b) => b.id.equals(bookId))).getSingle();
  final nameRow = await (db.select(db.bookNames)
        ..where((n) => n.bookId.equals(bookId) & n.translationId.equals(navigationTranslationId)))
      .getSingle();
  return BookInfo(
    id: book.id,
    testament: book.testament,
    chapterCount: book.chapterCount,
    name: nameRow.name,
  );
}
