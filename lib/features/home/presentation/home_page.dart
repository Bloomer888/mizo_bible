import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../library/presentation/history_page.dart';
import '../../library/presentation/library_providers.dart';
import '../../reader/data/reading_history_repository.dart';
import '../../reader/data/reading_progress_repository.dart';
import '../../reader/presentation/reader_page.dart';
import '../data/verse_of_the_day.dart';

final _mostRecentProgressProvider = FutureProvider.autoDispose<BookReadingPosition?>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadMostRecentReadingProgress(db);
});

final _verseOfTheDayProvider = FutureProvider.autoDispose<VerseOfTheDay?>((ref) async {
  final db = ref.watch(bibleDatabaseProvider);
  final names = await ref.watch(bookNamesMapProvider.future);
  return loadVerseOfTheDay(db, names);
});

final _readingStreakProvider = FutureProvider.autoDispose<int>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadReadingStreak(db);
});

final _readingDaysThisWeekProvider = FutureProvider.autoDispose<Set<DateTime>>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadReadingDaysThisWeek(db);
});

/// The Home tab: a way back into whichever book you were last reading
/// (or a nudge to start), today's verse, and a reading streak -- three
/// small cards, each independent of the others' loading state, not a
/// dashboard. Deliberately stops there.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progressAsync = ref.watch(_mostRecentProgressProvider);
    final namesAsync = ref.watch(bookNamesMapProvider);
    final verseAsync = ref.watch(_verseOfTheDayProvider);
    final streakAsync = ref.watch(_readingStreakProvider);
    final readingDaysAsync = ref.watch(_readingDaysThisWeekProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      // SingleChildScrollView, not the single-card Align/IntrinsicHeight
      // this used to be: a scroll view's child is always measured at
      // its own natural height (unbounded along the scroll axis), which
      // is a different layout protocol than being a direct Scaffold
      // body -- the stretch-to-fill-tab-height bug this project hit
      // before was specific to that direct-body case and doesn't
      // reappear here, verified live on-device with three stacked cards.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            switch ((progressAsync, namesAsync)) {
              (AsyncData(value: final position?), AsyncData(:final value)) => _ContinueReadingCard(
                  bookName: value[position.bookId] ?? '',
                  bookId: position.bookId,
                  chapter: position.chapter,
                  verse: position.verse,
                ),
              (AsyncData(value: null), _) => const _StartReadingCard(),
              _ => const SizedBox.shrink(),
            },
            if (verseAsync case AsyncData(value: final verse?)) ...[
              const SizedBox(height: 12),
              _VerseOfTheDayCard(verse: verse),
            ],
            if (streakAsync case AsyncData(value: final streak) when streak > 0) ...[
              const SizedBox(height: 12),
              _StreakCard(
                streak: streak,
                // Degrades to an all-empty strip for the one frame
                // before this resolves, rather than holding the whole
                // card back for a second, slower-resolving provider --
                // Riverpod repaints it the moment the real set lands.
                readingDays: readingDaysAsync.value ?? const {},
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  final String bookName;
  final int bookId;
  final int chapter;
  final int verse;

  const _ContinueReadingCard({
    required this.bookName,
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _HomeCard(
      icon: Icons.menu_book_rounded,
      label: l10n.continueReading,
      value: '$bookName $chapter:$verse',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderPage(bookId: bookId, targetChapter: chapter, targetVerse: verse),
        ),
      ),
    );
  }
}

class _StartReadingCard extends StatelessWidget {
  const _StartReadingCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _HomeCard(
      icon: Icons.auto_stories_rounded,
      label: l10n.startReadingPrompt,
      value: l10n.startReading,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReaderPage(bookId: 1)),
      ),
    );
  }
}

/// Same leading-icon/title/trailing-chevron shape as [EntryCard]
/// (core/widgets/entry_card.dart), just with a two-line title instead
/// of a title+subtitle pair -- built on ListTile rather than a
/// hand-rolled Row for the same reason EntryCard is: a Row here
/// stretched to fill the Scaffold's full body height instead of
/// sizing to its content (some ambient constraint between Card and
/// InkWell, not worth chasing further), where ListTile already does
/// the right thing. ListTile's own onTap is left unset deliberately --
/// _PressableScale owns the tap now, see its doc comment for why.
class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _HomeCard({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _PressableScale(
      onTap: onTap,
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary.withValues(alpha: 0.14),
            child: Icon(icon, color: scheme.primary),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

/// Deliberately shows both languages, not just English -- the app's
/// whole identity is the parallel text, and it's only two extra lines.
/// Tapping jumps straight to the verse in its full chapter context,
/// same destination the continue-reading card uses.
///
/// Sized to almost half the screen, per the user's explicit request
/// (2026-10-12) -- the label and reference sit up top, then a large
/// gap, then the quote. The gap is real spacing (not a stretched
/// background or oversized type), and scales with screen height via
/// MediaQuery rather than a fixed pixel value, so "almost half the
/// screen" holds across phone sizes instead of only looking right on
/// whatever device this was tuned on. minHeight on the ConstrainedBox
/// is a backstop for an unusually short verse -- the gap alone
/// comfortably clears it for every reference in the curated list as
/// checked on-device, but a future shorter entry shouldn't be able to
/// shrink the card back down.
class _VerseOfTheDayCard extends StatelessWidget {
  final VerseOfTheDay verse;
  const _VerseOfTheDayCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return _PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderPage(bookId: verse.bookId, targetChapter: verse.chapter, targetVerse: verse.verse),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenHeight * 0.46),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 17, color: scheme.primary),
                    const SizedBox(width: 7),
                    Text(
                      l10n.verseOfTheDay.toUpperCase(),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${verse.bookName} ${verse.chapter}:${verse.verse}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.primary),
                ),
                SizedBox(height: screenHeight * 0.16),
                Text(verse.englishText, style: const TextStyle(fontSize: 17, height: 1.5)),
                const SizedBox(height: 10),
                Text(
                  verse.mizoText,
                  style: TextStyle(fontSize: 15, height: 1.5, fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The streak card: a flickering flame, a count-up streak number, and
/// a Monday-start week strip showing which days this week already
/// have a logged visit -- replaces the old plain icon+number row with
/// something that's actually informative at a glance, not just
/// decorated, per the user's "too bland" feedback (2026-10-11).
class _StreakCard extends StatelessWidget {
  final int streak;
  final Set<DateTime> readingDays;
  final VoidCallback onTap;

  const _StreakCard({required this.streak, required this.readingDays, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return _PressableScale(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FlickeringFlame(color: scheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.readingStreak, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 4),
                        _CountUpStreakText(streak: streak),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.outlineVariant),
                ],
              ),
              const SizedBox(height: 18),
              _WeekStrip(readingDays: readingDays),
            ],
          ),
        ),
      ),
    );
  }
}

/// Counts up from 0 to [streak] on first appearance by re-rendering
/// the full templated string (l10n.dayStreak(value)) each animation
/// frame, rather than animating a bare number and splicing in static
/// " day streak" text around it -- keeps whatever word order a future
/// translation uses intact, since this never assumes the number comes
/// first. TweenAnimationBuilder only replays when streak itself
/// changes between builds (e.g. ticking over to a new day), not on
/// every unrelated Home rebuild -- see Flutter's own docs on how it
/// diffs tweens across didUpdateWidget.
class _CountUpStreakText extends StatelessWidget {
  final int streak;
  const _CountUpStreakText({required this.streak});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: streak),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(l10n.dayStreak(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700));
      },
    );
  }
}

/// A slow, continuous breathe -- scale and opacity both drift up and
/// back down -- not a literal flicker (that reads as jittery/broken at
/// icon size), just enough motion that the streak card doesn't look
/// static next to the newly-animated number beside it.
class _FlickeringFlame extends StatefulWidget {
  final Color color;
  const _FlickeringFlame({required this.color});

  @override
  State<_FlickeringFlame> createState() => _FlickeringFlameState();
}

class _FlickeringFlameState extends State<_FlickeringFlame> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      // child is built once, not on every tick -- only the Transform/
      // Opacity wrapper around it needs to rebuild each frame.
      child: CircleAvatar(
        radius: 26,
        backgroundColor: widget.color.withValues(alpha: 0.14),
        child: Icon(Icons.local_fire_department_rounded, color: widget.color),
      ),
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Opacity(
          opacity: 0.88 + (t * 0.12),
          child: Transform.scale(scale: 1.0 + (t * 0.08), child: child),
        );
      },
    );
  }
}

/// Monday-start to match the ISO week convention, same as the
/// production streak math in reading_history_repository.dart. Days
/// after today render as a faint, unfilled placeholder -- not an
/// empty/"missed" circle -- so the strip doesn't visually accuse the
/// user of having skipped a day that hasn't happened yet.
class _WeekStrip extends StatelessWidget {
  final Set<DateTime> readingDays;
  const _WeekStrip({required this.readingDays});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isToday = day == today;
        final isFuture = day.isAfter(today);
        final visited = readingDays.contains(day);

        return Column(
          children: [
            Text(
              _dayLabels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: visited ? scheme.primary : Colors.transparent,
                border: Border.all(
                  color: isFuture
                      ? scheme.outlineVariant.withValues(alpha: 0.35)
                      : (isToday ? scheme.primary : scheme.outlineVariant),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: visited ? Icon(Icons.local_fire_department_rounded, size: 14, color: scheme.onPrimary) : null,
            ),
          ],
        );
      }),
    );
  }
}

/// Every Home card's tap feedback: a small press-down scale instead of
/// Material's ripple -- a calmer, quieter feel that fits a devotional
/// app better than a splash effect, and the one thing that was
/// genuinely missing before (tapping a card did nothing until the next
/// screen simply appeared). Owns the only GestureDetector/tap handling
/// in the tree for its child -- the Cards underneath have their own
/// onTap left unset so there is exactly one recognizer per card, not
/// two competing for the same gesture. Wrapped in Semantics(button:
/// true) because a bare GestureDetector, unlike InkWell, doesn't
/// register as a tappable control for screen readers on its own.
class _PressableScale extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PressableScale({required this.onTap, required this.child});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
