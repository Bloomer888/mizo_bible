import 'package:flutter/material.dart';

import 'core/l10n_extension.dart';
import 'features/home/presentation/home_page.dart';
import 'features/more/presentation/more_page.dart';
import 'features/reader/presentation/reader_page.dart';

/// The app's three-tab shell: Home, Bible, More. Bible starts selected
/// (index 1), not Home -- opening straight into reading, continuing
/// exactly where the old single-screen app always has, matters more
/// than a conventional "Home is first" default. Home exists as
/// somewhere to deliberately visit, not something standing between
/// opening the app and reading.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 1;
  bool _navBarVisible = true;

  // Net scroll movement since the bar last flipped visibility, not just
  // "which way is this one notification pointing" -- see the doc comment
  // on _handleScroll below for why.
  double _scrollDelta = 0;

  static const _pages = [
    HomePage(),
    ReaderPage(bookId: 1),
    MorePage(),
  ];

  /// Hides the nav bar once scrolled-down movement crosses a small
  /// threshold, shows it once scrolled-up movement does -- accumulated
  /// across the whole gesture via ScrollUpdateNotification.scrollDelta,
  /// not decided from a single UserScrollNotification.direction reading.
  /// That used to flip the bar back immediately after showing it: a real
  /// swipe can report ScrollDirection.forward and then, a frame or two
  /// later as the same gesture settles, a brief ScrollDirection.reverse
  /// right before going idle (confirmed live via logcat, not assumed --
  /// scrolling up showed the bar for one frame then hid it again on that
  /// trailing flip, matching exactly what was reported: "scroll back up
  /// and ... it didn't" come back). A small threshold plus resetting the
  /// accumulator whenever the bar actually flips (or the gesture ends)
  /// is immune to that single-frame noise while still reacting to a real
  /// scroll well within one gesture.
  static const _scrollThreshold = 16.0;

  void _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta == null) return;
      _scrollDelta += delta;
      if (_scrollDelta > _scrollThreshold && _navBarVisible) {
        setState(() {
          _navBarVisible = false;
          _scrollDelta = 0;
        });
      } else if (_scrollDelta < -_scrollThreshold && !_navBarVisible) {
        setState(() {
          _navBarVisible = true;
          _scrollDelta = 0;
        });
      }
    } else if (notification is ScrollEndNotification) {
      _scrollDelta = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      extendBody: true,
      // IndexedStack, not a fresh page per tap: keeps each tab's own
      // scroll position and state alive across switches, same as the
      // reader already relies on for "reopen lands where you left off"
      // within a single visit.
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _handleScroll(notification);
          return false;
        },
        child: IndexedStack(index: _tabIndex, children: _pages),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        offset: _navBarVisible ? Offset.zero : const Offset(0, 1),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: l10n.bible,
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz_outlined),
              selectedIcon: const Icon(Icons.more_horiz_rounded),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );
  }
}
