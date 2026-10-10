import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

  static const _pages = [
    HomePage(),
    ReaderPage(bookId: 1),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      extendBody: true,
      // IndexedStack, not a fresh page per tap: keeps each tab's own
      // scroll position and state alive across switches, same as the
      // reader already relies on for "reopen lands where you left off"
      // within a single visit.
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final direction = notification.direction;
          if (direction == ScrollDirection.reverse && _navBarVisible) {
            setState(() => _navBarVisible = false);
          } else if (direction == ScrollDirection.forward && !_navBarVisible) {
            setState(() => _navBarVisible = true);
          }
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
            NavigationDestination(icon: const Icon(Icons.home_rounded), label: l10n.home),
            NavigationDestination(icon: const Icon(Icons.menu_book_rounded), label: l10n.bible),
            NavigationDestination(icon: const Icon(Icons.more_horiz_rounded), label: l10n.more),
          ],
        ),
      ),
    );
  }
}
