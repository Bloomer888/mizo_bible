import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/db/bible_database.dart';
import '../data/reader_repository.dart';
import '../domain/reader_item.dart';

/// Loads one book's reader items, keyed by canonical book id. autoDispose
/// since there's no reason to keep a book's whole verse list in memory
/// once nothing is reading it -- the book picker (a later phase) will
/// switch this family's parameter rather than ever juggling several
/// books' data at once.
final readerItemsProvider = FutureProvider.autoDispose.family<List<ReaderItem>, int>((ref, bookId) {
  final db = ref.watch(bibleDatabaseProvider);
  return loadBookReaderItems(db, bookId);
});

class ReaderPage extends ConsumerWidget {
  final int bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(readerItemsProvider(bookId));

    return Scaffold(
      // Book name lookup (content.book_names) and a real book/chapter
      // picker both belong to Phase 6 navigation, not this first reader
      // pass -- hardcoded for the one book this phase scrolls.
      appBar: AppBar(title: const Text('Genesis')),
      body: switch (itemsAsync) {
        AsyncData(:final value) => _ReaderList(items: value),
        AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReaderList extends StatelessWidget {
  final List<ReaderItem> items;
  const _ReaderList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _ReaderItemTile(item: items[index]),
    );
  }
}

class _ReaderItemTile extends StatelessWidget {
  final ReaderItem item;
  const _ReaderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (item) {
      ChapterHeader(:final chapter) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(child: Text('$chapter', style: theme.textTheme.headlineMedium)),
        ),
      SectionHeading(:final a, :final b) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _ParallelRow(
            a: Text(a ?? '', style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
            b: Text(b ?? '', style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
          ),
        ),
      VerseRow(:final label, :final a, :final b) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _ParallelRow(
            a: _VerseText(label: label, text: a),
            b: _VerseText(label: label, text: b),
          ),
        ),
    };
  }
}

/// Every reader row -- chapter headers excepted -- renders as this same
/// shape: the two translations side by side, aligned by construction.
/// Selection/scrolling always operate on the whole Row, never one side.
class _ParallelRow extends StatelessWidget {
  final Widget a;
  final Widget b;
  const _ParallelRow({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }
}

class _VerseText extends StatelessWidget {
  final String label;
  final String? text;
  const _VerseText({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final content = text;
    if (content == null) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label  ', style: Theme.of(context).textTheme.labelSmall),
          TextSpan(text: content),
        ],
      ),
    );
  }
}
