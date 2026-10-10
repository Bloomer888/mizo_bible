import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../about/presentation/about_page.dart';
import '../../auth/presentation/account_page.dart';
import '../../library/presentation/bookmarks_page.dart';
import '../../library/presentation/highlights_page.dart';
import '../../library/presentation/history_page.dart';
import '../../library/presentation/notes_page.dart';
import '../../navigation/data/book_repository.dart';
import '../../navigation/presentation/book_list_page.dart';
import '../../search/presentation/search_page.dart';
import '../data/reader_repository.dart';
import '../data/reading_history_repository.dart';
import '../data/reading_progress_repository.dart';
import '../data/verse_annotations_repository.dart';
import '../domain/reader_item.dart';
import 'reader_settings.dart';
import 'reader_settings_sheet.dart';
import 'verse_actions_sheet.dart';

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
  final int? targetChapter;
  final int? targetVerse;
  const ReaderPage({super.key, required this.bookId, this.targetChapter, this.targetVerse});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> with WidgetsBindingObserver {
  final _scrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();
  List<ReaderItem>? _items;
  int? _visibleTopIndex;
  bool _didInitialScroll = false;
  int? _restoredChapter;
  int? _restoredVerse;

  // Read once up front and kept, not re-read via ref.read from
  // dispose() -- ref becomes unsafe to use once a widget is unmounting,
  // which dispose() always is by definition.
  late final UserDatabase _userDb;

  @override
  void initState() {
    super.initState();
    _userDb = ref.read(userDatabaseProvider);
    // Only bother loading a saved position if the caller (search, a
    // bookmark, anything else that knows exactly where it wants to
    // land) didn't already give us one explicitly -- that always wins.
    if (widget.targetChapter == null) {
      _loadRestoredPosition();
    }
    _positionsListener.itemPositions.addListener(_onPositionsChanged);
    // dispose() alone only fires on in-app navigation (switching books,
    // popping back) -- pressing home or swiping to another app leaves
    // this widget mounted but backgrounded, so dispose() never runs at
    // all. That's the actually-common way people stop reading, so
    // position needs saving on that transition too, not just on
    // Navigator-driven teardown. (A true instant kill -- Android's own
    // "force stop", or the OS's low-memory killer -- gives no callback
    // of any kind to any app, Flutter or native; nothing can save
    // through that, so it isn't what this guards against.)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveCurrentPosition();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionsListener.itemPositions.removeListener(_onPositionsChanged);
    _saveCurrentPosition();
    super.dispose();
  }

  Future<void> _loadRestoredPosition() async {
    final position = await loadReadingProgress(_userDb, widget.bookId);
    if (!mounted || position == null) return;
    setState(() {
      _restoredChapter = position.chapter;
      _restoredVerse = position.verse;
    });
  }

  void _onPositionsChanged() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    _visibleTopIndex = positions.map((p) => p.index).reduce((a, b) => a < b ? a : b);
  }

  /// Fires once per page visit (back button, switching books via the
  /// book list, navigating away to search a result) -- not on every
  /// scroll frame, since "where did the reader last leave off" doesn't
  /// need finer resolution than that, and a write per visit instead of
  /// per frame is the obviously cheaper default.
  void _saveCurrentPosition() {
    final items = _items;
    final topIndex = _visibleTopIndex;
    if (items == null || topIndex == null) return;
    for (var i = topIndex; i < items.length; i++) {
      final item = items[i];
      if (item is VerseRow) {
        final verse = int.tryParse(item.label);
        if (verse != null) {
          // Best-effort: this fires from dispose(), which can't await,
          // so there's a real window where the provider container (and
          // the database with it) finishes tearing down before this
          // write lands -- losing the very last position update then is
          // an imperceptible cost, not a reason to let the exception
          // propagate and crash whatever's unwinding the widget tree.
          saveReadingProgress(_userDb, bookId: widget.bookId, chapter: item.chapter, verse: verse)
              .catchError((_) {});
        }
        return;
      }
    }
  }

  void _maybeScrollToTarget(List<ReaderItem> items, int chapter, int? verse) {
    if (_didInitialScroll) return;
    _didInitialScroll = true;
    // Once per page visit, logging whichever chapter this visit actually
    // settles on (restored, searched-to, or the plain default) -- not
    // every chapter scrolled past within the same visit.
    logChapterVisit(_userDb, bookId: widget.bookId, chapter: chapter).catchError((_) {});
    final index = _targetIndex(items, chapter, verse);
    if (index == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.jumpTo(index: index);
      }
    });
  }

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
    final fontScale = ref.watch(readerSettingsProvider.select((s) => s.fontScale));

    BookInfo? bookInfo;
    if (bookInfoAsync case AsyncData(:final value)) bookInfo = value;
    List<ReaderItem>? items;
    if (itemsAsync case AsyncData(:final value)) items = value;
    _items = items;

    final targetChapter = widget.targetChapter ?? _restoredChapter;
    if (items != null && targetChapter != null) {
      _maybeScrollToTarget(items, targetChapter, widget.targetVerse ?? _restoredVerse);
    }

    return Scaffold(
      drawer: const _ReaderDrawer(),
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookListPage()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(bookInfo?.name ?? '', overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 2),
                Icon(Icons.expand_more_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.search_rounded),
            tooltip: context.l10n.search,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            icon: const Icon(Icons.text_fields_rounded),
            tooltip: context.l10n.textSettings,
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const ReaderSettingsSheet(),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: context.l10n.chapters,
            onPressed: (bookInfo != null && items != null)
                ? () => _openChapterPicker(bookInfo!.chapterCount, _chapterIndex(items!))
                : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
        child: switch (itemsAsync) {
          AsyncData(:final value) => _ReaderList(
              items: value,
              scrollController: _scrollController,
              positionsListener: _positionsListener,
              bookId: widget.bookId,
              bookName: bookInfo?.name ?? '',
            ),
          AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
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

/// The item index for a search result's exact verse, falling back to its
/// chapter's start if that verse can't be pinned down (e.g. a future
/// merged-verse row whose label isn't a bare number -- doesn't happen
/// with today's 1-to-1 synthesis, but this degrades gracefully instead
/// of silently failing to scroll at all if that ever changes).
int? _targetIndex(List<ReaderItem> items, int chapter, int? verse) {
  if (verse != null) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is VerseRow && item.chapter == chapter && int.tryParse(item.label) == verse) {
        return i;
      }
    }
  }
  return _chapterIndex(items)[chapter];
}

class _ReaderDrawer extends StatelessWidget {
  const _ReaderDrawer();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    void openPage(Widget page) {
      Navigator.of(context).pop(); // close the drawer first
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.tertiary],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: scheme.onPrimary, size: 34),
                  const SizedBox(width: 14),
                  Text(
                    l10n.appTitle,
                    style: TextStyle(color: scheme.onPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.bookmark_rounded),
              title: Text(l10n.bookmarks),
              onTap: () => openPage(const BookmarksPage()),
            ),
            ListTile(
              leading: const Icon(Icons.format_color_fill_rounded),
              title: Text(l10n.highlights),
              onTap: () => openPage(const HighlightsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: Text(l10n.notes),
              onTap: () => openPage(const NotesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(l10n.history),
              onTap: () => openPage(const HistoryPage()),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.account_circle_rounded),
              title: Text(l10n.account),
              onTap: () => openPage(const AccountPage()),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.about),
              onTap: () => openPage(const AboutPage()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterGrid extends StatelessWidget {
  final int chapterCount;
  final ValueChanged<int> onSelected;
  const _ChapterGrid({required this.chapterCount, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 56,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: chapterCount,
          itemBuilder: (context, i) {
            final chapter = i + 1;
            return Material(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onSelected(chapter),
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Text(
                    '$chapter',
                    style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
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
  final ItemPositionsListener positionsListener;
  final int bookId;
  final String bookName;
  const _ReaderList({
    required this.items,
    required this.scrollController,
    required this.positionsListener,
    required this.bookId,
    required this.bookName,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: scrollController,
      itemPositionsListener: positionsListener,
      itemCount: items.length,
      itemBuilder: (context, index) => _ReaderItemTile(item: items[index], bookId: bookId, bookName: bookName),
    );
  }
}

class _ReaderItemTile extends ConsumerWidget {
  final ReaderItem item;
  final int bookId;
  final String bookName;
  const _ReaderItemTile({required this.item, required this.bookId, required this.bookName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lineHeight = ref.watch(readerSettingsProvider.select((s) => s.lineHeightScale));
    return switch (item) {
      ChapterHeader(:final chapter) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Text(
              '$chapter',
              style: theme.textTheme.headlineMedium?.copyWith(height: lineHeight),
            ),
          ),
        ),
      SectionHeading(:final a, :final b) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _ParallelRow(
            a: Text(
              a ?? '',
              style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, height: lineHeight),
            ),
            b: Text(
              b ?? '',
              style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, height: lineHeight),
            ),
          ),
        ),
      VerseRow(:final chapter, :final label, :final a, :final b) => _VerseRowTile(
          bookId: bookId,
          bookName: bookName,
          chapter: chapter,
          label: label,
          a: a,
          b: b,
        ),
    };
  }
}

/// The one reader row type that's interactive: long-press opens bookmark/
/// highlight/note/copy/share (verse_actions_sheet.dart). Watches its own
/// annotation state directly rather than the whole book's at once --
/// cheap per-row local SQLite reads, and avoids rebuilding every visible
/// row whenever any single verse's annotations change.
class _VerseRowTile extends ConsumerWidget {
  final int bookId;
  final String bookName;
  final int chapter;
  final String label;
  final String? a;
  final String? b;

  const _VerseRowTile({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.label,
    required this.a,
    required this.b,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = int.tryParse(label);
    final annotationsAsync =
        verse == null ? null : ref.watch(verseAnnotationsProvider((bookId, chapter, verse)));
    final annotations = switch (annotationsAsync) {
      AsyncData(:final value) => value,
      _ => VerseAnnotations.none,
    };
    final highlightColor = annotations.highlightColor == null
        ? null
        : highlightColors[annotations.highlightColor]?.withValues(alpha: 0.35);

    return InkWell(
      onLongPress: verse == null
          ? null
          : () => openVerseActions(
                context,
                bookId: bookId,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                mizoText: a,
                englishText: b,
              ),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: EdgeInsets.symmetric(horizontal: highlightColor == null ? 0 : 6, vertical: highlightColor == null ? 0 : 2),
        padding: EdgeInsets.symmetric(horizontal: highlightColor == null ? 16 : 10, vertical: 4),
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: _ParallelRow(
          a: _VerseText(label: label, text: a, annotations: annotations),
          b: _VerseText(label: label, text: b, annotations: null),
        ),
      ),
    );
  }
}

/// Every reader row -- chapter headers excepted -- renders as this same
/// shape: the two translations side by side, aligned by construction, in
/// parallel mode. Selection/scrolling always operate on the whole Row,
/// never one side. Single-language mode and swap sides are both purely
/// display concerns handled here -- the underlying data's a/b identity
/// (Mizo/English) never changes, only which gets shown and on which side.
class _ParallelRow extends ConsumerWidget {
  final Widget a;
  final Widget b;
  const _ParallelRow({required this.a, required this.b});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(readerSettingsProvider.select((s) => s.mode));

    if (mode == ReadingMode.mizoOnly) return a;
    if (mode == ReadingMode.englishOnly) return b;

    final swapped = ref.watch(readerSettingsProvider.select((s) => s.swapped));
    final left = swapped ? b : a;
    final right = swapped ? a : b;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

class _VerseText extends ConsumerWidget {
  final String label;
  final String? text;
  // Non-null only on the side that should actually render the bookmark/
  // note indicators -- showing them on both columns would just duplicate
  // the same two icons next to every verse.
  final VerseAnnotations? annotations;
  const _VerseText({required this.label, required this.text, this.annotations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = text;
    if (content == null) return const SizedBox.shrink();

    final lineHeight = ref.watch(readerSettingsProvider.select((s) => s.lineHeightScale));
    final baseStyle = DefaultTextStyle.of(context).style.copyWith(height: lineHeight);
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final iconColor = labelStyle?.color ?? Theme.of(context).iconTheme.color;
    final markers = annotations;

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '$label  ', style: labelStyle),
          if (markers?.bookmarked ?? false)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.bookmark, size: 14, color: iconColor),
            ),
          if (markers?.hasNote ?? false)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.edit_note, size: 14, color: iconColor),
            ),
          if ((markers?.bookmarked ?? false) || (markers?.hasNote ?? false)) const TextSpan(text: ' '),
          TextSpan(text: content),
        ],
      ),
    );
  }
}
