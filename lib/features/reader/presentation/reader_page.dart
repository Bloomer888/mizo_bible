import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/l10n_extension.dart';
import '../../navigation/data/book_repository.dart';
import '../../navigation/presentation/book_list_page.dart';
import '../data/reader_repository.dart';
import '../domain/reader_item.dart';

/// Loads one book's reader items, keyed by canonical book id. autoDispose
/// since there's no reason to keep a book's whole verse list in memory
/// once nothing is reading it -- switching books (the book list) always
/// replaces this family's parameter rather than juggling several books'
/// data at once.
final readerItemsProvider = FutureProvider.autoDispose.family<List<ReaderItem>, int>((ref, bookId) {
  final db = ref.watch(bibleDatabaseProvider);
  return loadBookReaderItems(db, bookId);
});

final bookInfoProvider = FutureProvider.autoDispose.family<BookInfo, int>((ref, bookId) {
  final db = ref.watch(bibleDatabaseProvider);
  return loadBookInfo(db, bookId);
});

class ReaderPage extends ConsumerStatefulWidget {
  final int bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  final _scrollController = ItemScrollController();

  void _openChapterPicker(int chapterCount, Map<int, int> chapterIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ChapterGrid(
        chapterCount: chapterCount,
        onSelected: (chapter) {
          Navigator.of(context).pop();
          final index = chapterIndex[chapter];
          if (index != null && _scrollController.isAttached) {
            _scrollController.scrollTo(
              index: index,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(readerItemsProvider(widget.bookId));
    final bookInfoAsync = ref.watch(bookInfoProvider(widget.bookId));

    BookInfo? bookInfo;
    if (bookInfoAsync case AsyncData(:final value)) bookInfo = value;
    List<ReaderItem>? items;
    if (itemsAsync case AsyncData(:final value)) items = value;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookListPage()),
          ),
          child: Text(bookInfo?.name ?? ''),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: context.l10n.chapters,
            onPressed: (bookInfo != null && items != null)
                ? () => _openChapterPicker(bookInfo!.chapterCount, _chapterIndex(items!))
                : null,
          ),
        ],
      ),
      body: switch (itemsAsync) {
        AsyncData(:final value) => _ReaderList(items: value, scrollController: _scrollController),
        AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

Map<int, int> _chapterIndex(List<ReaderItem> items) {
  final index = <int, int>{};
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is ChapterHeader) index[item.chapter] = i;
  }
  return index;
}

class _ChapterGrid extends StatelessWidget {
  final int chapterCount;
  final ValueChanged<int> onSelected;
  const _ChapterGrid({required this.chapterCount, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 56,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: chapterCount,
          itemBuilder: (context, i) {
            final chapter = i + 1;
            return InkWell(
              onTap: () => onSelected(chapter),
              borderRadius: BorderRadius.circular(8),
              child: Center(child: Text('$chapter')),
            );
          },
        ),
      ),
    );
  }
}

class _ReaderList extends StatelessWidget {
  final List<ReaderItem> items;
  final ItemScrollController scrollController;
  const _ReaderList({required this.items, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: scrollController,
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
