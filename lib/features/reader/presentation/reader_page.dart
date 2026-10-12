import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../navigation/data/book_repository.dart';
import '../../navigation/presentation/book_language_settings.dart';
import '../../navigation/presentation/book_list_page.dart';
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
  final language = ref.watch(bookNameLanguageProvider);
  return loadBookInfo(db, bookId, translationId: translationIdFor(language));
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
  bool _topBarVisible = true;
  // True while any of the picker's three dropdown fields has focus --
  // i.e. its popup is open or was just closed. DropdownMenu's popup is
  // built via OverlayPortal, which keeps it a logical descendant of
  // wherever the picker sits for Notification-bubbling purposes (unlike
  // the legacy raw-Overlay approach, which would have isolated it) --
  // so scrolling inside the popup's own list produces UserScrollNotification
  // that would otherwise reach the NotificationListener below and hide
  // this page's top bar (and, bubbling further, app_shell's bottom nav
  // too) as if the reader itself were being scrolled. Swallowing that
  // notification at the picker (see build() below) stops the bar-hiding,
  // but doesn't by itself stop the background list's own Scrollable from
  // also claiming the same drag -- confirmed on a real device, scrolling
  // the open book dropdown moved the chapter content behind it. This
  // flag locks the list's physics for as long as a dropdown might be
  // open, which is also just correct UX: scrolling the Bible text while
  // a book/chapter/verse picker is open was never a meaningful gesture.
  bool _pickerMenuActive = false;

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

    final topBar = AppBar(
      title: Text(bookInfo?.name ?? ''),
      actions: [
        IconButton.filledTonal(
          icon: const Icon(Icons.text_fields_rounded),
          tooltip: context.l10n.textSettings,
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (_) => const ReaderSettingsSheet(),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: (bookInfo != null && items != null)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                // Absorbs the ScrollNotification that bubbles up from the
                // open dropdown's own popup list (see _pickerMenuActive's
                // doc comment) before it reaches this page's own
                // NotificationListener<UserScrollNotification> below, or
                // app_shell.dart's further up -- returning true marks a
                // notification as handled, which stops it from bubbling
                // any further.
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) => true,
                  child: _BookChapterVersePicker(
                    bookId: widget.bookId,
                    bookName: bookInfo.name,
                    chapterCount: bookInfo.chapterCount,
                    items: items,
                    initialChapter: targetChapter ?? 1,
                    initialVerse: widget.targetVerse ?? _restoredVerse ?? 1,
                    onChapterSelected: (chapter) {
                      final index = _chapterIndex(items!)[chapter];
                      if (index != null && _scrollController.isAttached) {
                        _scrollController.scrollTo(index: index, duration: const Duration(milliseconds: 300));
                      }
                    },
                    onVerseSelected: (chapter, verse) {
                      final index = _targetIndex(items!, chapter, verse);
                      if (index != null && _scrollController.isAttached) {
                        _scrollController.scrollTo(index: index, duration: const Duration(milliseconds: 300));
                      }
                    },
                    onMenuActiveChanged: (active) {
                      if (active == _pickerMenuActive) return;
                      setState(() => _pickerMenuActive = active);
                    },
                  ),
                ),
              ),
            )
          : null,
    );
    // AppBar's own toolbarHeight (kToolbarHeight, 56) plus the picker's
    // declared bottom height, plus the status bar inset -- reserved as
    // the list's own top padding (not a wrapping Padding around it) so
    // this scrolls away WITH the content instead of leaving a dead gap
    // once the bar itself has slid out of view.
    final topBarHeight =
        MediaQuery.of(context).padding.top + kToolbarHeight + (topBar.bottom?.preferredSize.height ?? 0);

    return Scaffold(
      // SliverAppBar(floating/snap) doesn't work here: it relies on the
      // sliver geometry protocol for its scroll position, but
      // ScrollablePositionedList manages its own internal Scrollable
      // rather than being a sliver, so it never feeds that protocol --
      // confirmed empirically (content scrolled, the bar never moved).
      // UserScrollNotification is a different, higher-level signal that
      // this list does bubble correctly (already proven by the bottom
      // nav bar's identical hide/show in app_shell.dart), so that's what
      // drives this instead.
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final direction = notification.direction;
          if (direction == ScrollDirection.reverse && _topBarVisible) {
            setState(() => _topBarVisible = false);
          } else if (direction == ScrollDirection.forward && !_topBarVisible) {
            setState(() => _topBarVisible = true);
          }
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
                child: switch (itemsAsync) {
                  AsyncData(:final value) => _ReaderList(
                      items: value,
                      scrollController: _scrollController,
                      positionsListener: _positionsListener,
                      bookId: widget.bookId,
                      bookName: bookInfo?.name ?? '',
                      topPadding: topBarHeight,
                      scrollLocked: _pickerMenuActive,
                    ),
                  AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // AppBar needs a bounded height here -- Scaffold.appBar
              // normally supplies one implicitly; a bare Positioned with
              // no height (just top/left/right) gives it unbounded
              // height instead, which breaks AppBar's internal layout.
              height: topBarHeight,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                offset: _topBarVisible ? Offset.zero : const Offset(0, -1),
                child: topBar,
              ),
            ),
          ],
        ),
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

class _ReaderList extends StatelessWidget {
  final List<ReaderItem> items;
  final ItemScrollController scrollController;
  final ItemPositionsListener positionsListener;
  final int bookId;
  final String bookName;
  // Reserves space for the overlaid top bar (reader_page.dart's build())
  // as this list's own top padding, not an ancestor Padding -- so it
  // scrolls away together with the content behind the bar once the bar
  // has slid out of view, instead of leaving a fixed dead gap.
  final double topPadding;
  // True while the book/chapter/verse picker's popup might be open --
  // see _pickerMenuActive in _ReaderPageState for why this list needs
  // its own scrolling disabled for that duration, not just the picker
  // fixed in isolation.
  final bool scrollLocked;
  const _ReaderList({
    required this.items,
    required this.scrollController,
    required this.positionsListener,
    required this.bookId,
    required this.bookName,
    required this.topPadding,
    required this.scrollLocked,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: scrollController,
      itemPositionsListener: positionsListener,
      itemCount: items.length,
      padding: EdgeInsets.only(top: topPadding),
      physics: scrollLocked ? const NeverScrollableScrollPhysics() : null,
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

/// Direct book/chapter/verse navigation -- replaces the old pair of
/// "tap the title for a book list" and "tap a grid icon for chapters"
/// with one row that jumps anywhere in a tap or two, covering the
/// common "I already know exactly where I want to go" case without
/// needing full-text search (still reachable from the drawer).
class _BookChapterVersePicker extends ConsumerStatefulWidget {
  final int bookId;
  final String bookName;
  final int chapterCount;
  final List<ReaderItem> items;
  final int initialChapter;
  final int initialVerse;
  final ValueChanged<int> onChapterSelected;
  final void Function(int chapter, int verse) onVerseSelected;
  // Fires whenever any of the three dropdowns' focus state changes --
  // DropdownMenu requests focus on its field when it opens, so "any
  // field focused" is this picker's own signal for "a popup might be
  // open," passed up so the reader page can lock its own list's
  // scrolling for that duration (see _pickerMenuActive in reader_page.dart).
  final ValueChanged<bool> onMenuActiveChanged;

  const _BookChapterVersePicker({
    required this.bookId,
    required this.bookName,
    required this.chapterCount,
    required this.items,
    required this.initialChapter,
    required this.initialVerse,
    required this.onChapterSelected,
    required this.onVerseSelected,
    required this.onMenuActiveChanged,
  });

  @override
  ConsumerState<_BookChapterVersePicker> createState() => _BookChapterVersePickerState();
}

class _BookChapterVersePickerState extends ConsumerState<_BookChapterVersePicker> {
  late int _chapter;
  late int _verse;
  final _bookFocus = FocusNode();
  final _chapterFocus = FocusNode();
  final _verseFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // widget.* isn't safe to read in field initializers (the framework
    // assigns `widget` after this State is constructed) -- initState is
    // the first point it's guaranteed set.
    _chapter = widget.initialChapter;
    _verse = widget.initialVerse;
    for (final node in [_bookFocus, _chapterFocus, _verseFocus]) {
      node.addListener(_notifyMenuActive);
    }
  }

  @override
  void dispose() {
    for (final node in [_bookFocus, _chapterFocus, _verseFocus]) {
      node
        ..removeListener(_notifyMenuActive)
        ..dispose();
    }
    super.dispose();
  }

  void _notifyMenuActive() {
    widget.onMenuActiveChanged(_bookFocus.hasFocus || _chapterFocus.hasFocus || _verseFocus.hasFocus);
  }

  List<int> _versesInChapter(int chapter) {
    final verses = <int>[];
    for (final item in widget.items) {
      if (item is VerseRow && item.chapter == chapter) {
        final v = int.tryParse(item.label);
        if (v != null) verses.add(v);
      }
    }
    return verses;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookListProvider);
    final language = ref.watch(bookNameLanguageProvider);
    final verses = _versesInChapter(_chapter);
    final verseSelection = verses.contains(_verse) ? _verse : (verses.isEmpty ? null : verses.first);
    final scheme = Theme.of(context).colorScheme;
    // Overrides the app-wide borderless/filled InputDecorationTheme
    // (app_theme.dart) for just these three fields -- no wrapping box
    // around the group at all, just each field as its own outlined
    // control sitting directly on the app bar, matching its fill
    // exactly (scheme.surfaceContainerLow, same as AppBarTheme.backgroundColor)
    // so only the border defines each one.
    final fieldDecoration = InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          // Book names run far longer than chapter/verse numbers ever
          // do (up to "1 Thessalonians"), so this field needs the
          // lion's share of the row -- 4:3:3 clipped common names like
          // "Numbers" once the box's own padding started eating into
          // the available width.
          flex: 5,
          child: switch (booksAsync) {
            AsyncData(:final value) => DropdownMenu<int>(
                focusNode: _bookFocus,
                initialSelection: widget.bookId,
                label: Text(language.booksLabel(context.l10n)),
                inputDecorationTheme: fieldDecoration,
                expandedInsets: EdgeInsets.zero,
                menuHeight: 420,
                dropdownMenuEntries: [
                  for (final book in value) DropdownMenuEntry(value: book.id, label: book.name),
                ],
                onSelected: (bookId) {
                  if (bookId == null || bookId == widget.bookId) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => ReaderPage(bookId: bookId)),
                  );
                },
              ),
            _ => const SizedBox.shrink(),
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: DropdownMenu<int>(
            key: ValueKey('chapter-${widget.bookId}-$_chapter'),
            focusNode: _chapterFocus,
            initialSelection: _chapter,
            label: Text(language.chaptersLabel(context.l10n)),
            inputDecorationTheme: fieldDecoration,
            expandedInsets: EdgeInsets.zero,
            menuHeight: 420,
            dropdownMenuEntries: [
              for (var c = 1; c <= widget.chapterCount; c++) DropdownMenuEntry(value: c, label: '$c'),
            ],
            onSelected: (chapter) {
              if (chapter == null || chapter == _chapter) return;
              setState(() {
                _chapter = chapter;
                _verse = 1;
              });
              widget.onChapterSelected(chapter);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: DropdownMenu<int>(
            key: ValueKey('verse-${widget.bookId}-$_chapter'),
            focusNode: _verseFocus,
            initialSelection: verseSelection,
            label: Text(language.verseLabel(context.l10n)),
            inputDecorationTheme: fieldDecoration,
            expandedInsets: EdgeInsets.zero,
            menuHeight: 420,
            dropdownMenuEntries: [
              for (final v in verses) DropdownMenuEntry(value: v, label: '$v'),
            ],
            onSelected: (verse) {
              if (verse == null || verse == _verse) return;
              setState(() => _verse = verse);
              widget.onVerseSelected(_chapter, verse);
            },
          ),
        ),
      ],
    );
  }
}
