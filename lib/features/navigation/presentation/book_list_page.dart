import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/l10n_extension.dart';
import '../../reader/presentation/reader_page.dart';
import '../data/book_repository.dart';

final bookListProvider = FutureProvider.autoDispose<List<BookInfo>>((ref) {
  final db = ref.watch(bibleDatabaseProvider);
  return loadAllBooks(db);
});

class BookListPage extends ConsumerWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.books)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BookInfo book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(book.name),
      trailing: Text('${book.chapterCount}'),
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ReaderPage(bookId: book.id)),
        );
      },
    );
  }
}
