import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/l10n_extension.dart';
import '../../reader/presentation/reader_page.dart';
import '../data/book_repository.dart';
import 'book_language_settings.dart';

final bookListProvider = FutureProvider.autoDispose<List<BookInfo>>((ref) {
  final db = ref.watch(bibleDatabaseProvider);
  final language = ref.watch(bookNameLanguageProvider);
  return loadAllBooks(db, translationId: translationIdFor(language));
});

class BookListPage extends ConsumerWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookListProvider);
    final language = ref.watch(bookNameLanguageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(language.booksLabel(context.l10n))),
      body: switch (booksAsync) {
        AsyncData(:final value) => _BookList(books: value),
        AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BookInfo> books;
  const _BookList({required this.books});

  @override
  Widget build(BuildContext context) {
    final oldTestament = books.where((b) => b.testament == 'OT').toList();
    final newTestament = books.where((b) => b.testament == 'NT').toList();

    return ListView(
      children: [
        _TestamentHeader(context.l10n.oldTestament),
        for (final book in oldTestament) _BookTile(book: book),
        _TestamentHeader(context.l10n.newTestament),
        for (final book in newTestament) _BookTile(book: book),
      ],
    );
  }
}

class _TestamentHeader extends StatelessWidget {
  final String title;
  const _TestamentHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BookInfo book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(book.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${book.chapterCount}',
            style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ReaderPage(bookId: book.id)),
          );
        },
      ),
    );
  }
}
