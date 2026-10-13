import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../library/presentation/library_providers.dart';
import '../../premium/data/premium_providers.dart';
import '../../reader/data/reading_progress_repository.dart';
import '../../reader/data/verse_annotations_repository.dart';
import '../../reader/presentation/reader_page.dart';
import '../../reader/presentation/verse_actions_sheet.dart' show verseAnnotationsProvider;
import '../../reading_plans/data/reading_plan.dart';
import '../../reading_plans/data/reading_plan_progress_repository.dart';
import '../../reading_plans/presentation/reading_plan_providers.dart';
import '../data/streak_repository.dart';
import '../data/verse_of_the_day.dart';

final _mostRecentProgressProvider = FutureProvider.autoDispose<BookReadingPosition?>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadMostRecentReadingProgress(db);
});

final _verseOfTheDayProvider = FutureProvider.autoDispose<VerseOfTheDay?>((ref) async {
  final bibleDb = ref.watch(bibleDatabaseProvider);
  final userDb = ref.watch(userDatabaseProvider);
  final names = await ref.watch(bookNamesMapProvider.future);
  final references = await loadActiveDailyVerseReferences(userDb);
  return loadVerseOfTheDay(bibleDb, names, references: references);
});

final _streakProvider = FutureProvider.autoDispose<int>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadStreak(db);
});

final _bestStreakProvider = FutureProvider.autoDispose<int>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadBestStreak(db);
});

final _streakDaysThisWeekProvider = FutureProvider.autoDispose<Set<DateTime>>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadStreakDaysThisWeek(db);
});

final _checkedInTodayProvider = FutureProvider.autoDispose<bool>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return isCheckedInToday(db);
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
    final isPremium = ref.watch(isPremiumProvider);
    final planAsync = ref.watch(activePlanProgressProvider);

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
            // Premium-gated and only once a plan is active and not yet
            // finished -- never shown to free users regardless of what
            // might be sitting in their local progress table (e.g. a
            // lapsed subscriber), and stops appearing once the plan is
            // done rather than lingering with nothing left to do.
            if (planAsync case AsyncData(value: final planState?) when isPremium && !planState.isComplete) ...[
              const SizedBox(height: 12),
              _ReadingPlanCard(state: planState),
            ],
            const SizedBox(height: 12),
            const _StreakCard(),
          ],
        ),
      ),
    );
  }
}

/// The one Home card with a trailing action beyond the chevron -- a
/// bookmark toggle, so turning "where I automatically stopped" into
/// "a spot I deliberately want to keep" is one tap instead of opening
/// the reader first (user's suggestion, 2026-10-12: Continue Reading's
/// auto-tracked position and a bookmark are different things on
/// purpose -- see [[project-premium-decisions]]-adjacent reasoning in
/// memory -- but nothing stopped them being one tap apart). Only on
/// this card, not _StartReadingCard: there's no tracked position yet
/// to bookmark before any reading has happened.
class _ContinueReadingCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final key = (bookId, chapter, verse);
    final isBookmarked = ref.watch(verseAnnotationsProvider(key)).value?.bookmarked ?? false;

    return _HomeCard(
      icon: Icons.menu_book_rounded,
      label: l10n.continueReading,
      value: '$bookName $chapter:$verse',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderPage(bookId: bookId, targetChapter: chapter, targetVerse: verse),
        ),
      ),
      // A real IconButton, not a bare Icon -- same reason the Reading
      // Plan card's "Mark as read" is a real button and not just
      // tappable-looking text: it needs its own gesture recognizer so
      // this tap doesn't also trigger the card's own onTap above.
      trailing: IconButton(
        icon: Icon(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: scheme.primary,
        ),
        tooltip: isBookmarked ? l10n.removeBookmark : l10n.addBookmark,
        onPressed: () async {
          await toggleBookmark(ref.read(userDatabaseProvider), bookId: bookId, chapter: chapter, verse: verse);
          ref.invalidate(verseAnnotationsProvider(key));
        },
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

  /// An extra tappable widget before the chevron (e.g. the bookmark
  /// toggle on _ContinueReadingCard) -- optional, since most cards
  /// using this just want the plain chevron.
  final Widget? trailing;

  const _HomeCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

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
              Text(value, style: AppTypography.weight(const TextStyle(fontSize: 20), FontWeight.w700)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?trailing,
              Icon(Icons.chevron_right_rounded, color: scheme.outlineVariant),
            ],
          ),
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
/// Sized noticeably larger than a normal Home card, per the user's
/// explicit request (2026-10-12, spacing trimmed down a bit the same
/// day after it first shipped too large) -- the label and reference
/// sit up top, then a gap, then the quote. The gap is real spacing
/// (not a stretched background or oversized type), and scales with
/// screen height via MediaQuery rather than a fixed pixel value, so
/// the proportions hold across phone sizes instead of only looking
/// right on whatever device this was tuned on. minHeight on the
/// ConstrainedBox is a real floor, not just a redundant backstop --
/// for a short verse (or now, with the trimmed gap, even some typical
/// ones) natural content falls short of it, and the extra space reads
/// fine landing below the quote rather than needing to all be in the
/// one gap above it.
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
        constraints: BoxConstraints(minHeight: screenHeight * 0.38),
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
                      style: AppTypography.weight(
                        TextStyle(color: scheme.primary, fontSize: 13, letterSpacing: 0.7),
                        FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${verse.bookName} ${verse.chapter}:${verse.verse}',
                  style: AppTypography.weight(TextStyle(fontSize: 16, color: scheme.primary), FontWeight.w700),
                ),
                SizedBox(height: screenHeight * 0.10),
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

/// Today's reading-plan assignment, a progress line, and a "mark as
/// read" button -- a second, separate tap target nested inside the
/// card's own _PressableScale. Material buttons claim their own taps
/// before they'd bubble up to an ancestor GestureDetector, so the two
/// coexist correctly: tapping the button marks the day done without
/// triggering the card's own navigate-to-reader tap underneath it.
class _ReadingPlanCard extends ConsumerWidget {
  final ReadingPlanState state;
  const _ReadingPlanCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final namesAsync = ref.watch(bookNamesMapProvider);
    final today = state.plan.days[state.currentDay! - 1];
    final firstReading = today.first;

    return _PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderPage(bookId: firstReading.$1, targetChapter: firstReading.$2),
        ),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.readingPlan.toUpperCase(),
                    style: AppTypography.weight(
                      TextStyle(color: scheme.primary, fontSize: 12, letterSpacing: 0.6),
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(state.plan.name, style: AppTypography.weight(const TextStyle(fontSize: 18), FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                l10n.dayOfTotal(state.currentDay!, state.plan.totalDays),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Text(
                namesAsync.value == null ? '' : formatPlanDayReading(today, namesAsync.value!),
                style: AppTypography.weight(const TextStyle(fontSize: 16), FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () async {
                    await markReadingPlanDayComplete(
                      ref.read(userDatabaseProvider),
                      planId: state.planId,
                      day: state.currentDay!,
                    );
                    ref.invalidate(activePlanProgressProvider);
                  },
                  child: Text(l10n.markAsRead),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The streak card: a flickering flame, a count-up streak number, a
/// personal-best stat, and a Sunday-start week strip -- now a manual
/// daily check-in (tap today's circle to mark it) instead of a passive
/// log of any chapter visited, per the user's explicit request
/// (2026-10-13). Two things changed together on purpose, not just a
/// visual refresh: the old version derived the streak from
/// reading_history and hid the entire card once it hit zero -- a real
/// bug the user hit directly ("it disappear") -- which a manual,
/// always-rendered check-in fixes as a natural side effect, since
/// there's now always something to tap rather than nothing to show.
class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  Future<void> _checkIn(WidgetRef ref) async {
    await checkInToday(ref.read(userDatabaseProvider));
    unawaited(HapticFeedback.mediumImpact());
    ref.invalidate(_streakProvider);
    ref.invalidate(_bestStreakProvider);
    ref.invalidate(_streakDaysThisWeekProvider);
    ref.invalidate(_checkedInTodayProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final streak = ref.watch(_streakProvider).value ?? 0;
    final best = ref.watch(_bestStreakProvider).value ?? 0;
    final checkedDays = ref.watch(_streakDaysThisWeekProvider).value ?? const {};
    final checkedInToday = ref.watch(_checkedInTodayProvider).value ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FlickeringFlame(color: scheme.primary, streak: streak),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.readingStreak.toUpperCase(),
                        style: AppTypography.weight(
                          TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, letterSpacing: 0.6),
                          FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _CountUpStreakText(streak: streak),
                      // Only once it's something to actually mention --
                      // "5 day streak / Best: 5 days" right after tying
                      // your own record reads as noise, not insight.
                      if (best > streak) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.bestStreak(best),
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _WeekStrip(
              checkedDays: checkedDays,
              checkedInToday: checkedInToday,
              onCheckIn: () => _checkIn(ref),
            ),
            if (!checkedInToday) ...[
              const SizedBox(height: 14),
              Text(
                streak > 0 ? l10n.continueStreakPrompt : l10n.startStreakPrompt,
                textAlign: TextAlign.center,
                style: AppTypography.weight(TextStyle(color: scheme.primary, fontSize: 13), FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Counts up from the previously-displayed value to the new [streak]
/// whenever it changes (not just from 0 on first appearance -- a fresh
/// check-in ticking 5 to 6 animates that one step, not a replay from
/// scratch) by re-rendering the full templated string (l10n.dayStreak)
/// each frame, rather than animating a bare number and splicing in
/// static " day streak" text around it -- keeps whatever word order a
/// future translation uses intact, since this never assumes the number
/// comes first. Sized as a real hero stat (bigger, heavier, tighter
/// letter-spacing than this card used before) rather than body text
/// that happens to be bold -- the number is the one thing on this card
/// worth a glance from across the room.
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
        return Text(
          l10n.dayStreak(value),
          style: AppTypography.weight(
            const TextStyle(fontSize: 26, letterSpacing: -0.3, height: 1.1),
            FontWeight.w800,
          ),
        );
      },
    );
  }
}

/// A slow, continuous breathe -- scale and opacity both drift up and
/// back down -- not a literal flicker (that reads as jittery/broken at
/// icon size), just enough motion that the streak card doesn't look
/// static next to the newly-animated number beside it.
///
/// Five days running earns a visibly hotter flame -- a warmer color, a
/// bigger breathe, and a second, larger, fainter flame layered behind
/// the main one -- per the user's explicit ask ("more fire on that or
/// something") for the streak to feel more alive at a real milestone.
/// Deliberately just the one threshold rather than an ever-escalating
/// ladder of them: the same message said this shouldn't be overkill.
class _FlickeringFlame extends StatefulWidget {
  final Color color;
  final int streak;
  const _FlickeringFlame({required this.color, required this.streak});

  @override
  State<_FlickeringFlame> createState() => _FlickeringFlameState();
}

class _FlickeringFlameState extends State<_FlickeringFlame> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _milestoneStreak = 5;

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
    final hot = widget.streak >= _milestoneStreak;
    final flameColor = hot ? Color.lerp(widget.color, Colors.deepOrange, 0.55)! : widget.color;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (hot)
              Opacity(
                opacity: 0.3 + t * 0.25,
                child: Transform.scale(
                  scale: 1.3 + t * 0.2,
                  child: Icon(Icons.local_fire_department_rounded, size: 34, color: flameColor),
                ),
              ),
            Opacity(
              opacity: 0.88 + (t * 0.12),
              child: Transform.scale(
                scale: 1.0 + (t * (hot ? 0.14 : 0.08)),
                child: CircleAvatar(
                  radius: hot ? 28 : 26,
                  backgroundColor: flameColor.withValues(alpha: 0.14),
                  child: Icon(Icons.local_fire_department_rounded, color: flameColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sunday-start, per the user's explicit request -- a deliberate
/// deviation from the ISO week convention (and from the Monday-start
/// this card used before), matched by loadStreakDaysThisWeek in
/// streak_repository.dart so the two stay in agreement about which 7
/// days are "this week." Days after today render as a faint, unfilled
/// placeholder -- not an empty/"missed" circle -- so the strip doesn't
/// visually accuse the user of having skipped a day that hasn't
/// happened yet. Today's slot is the one genuinely interactive element:
/// _TodayCheckInCircle owns its own tap and animation, separate from
/// the plain _DayCircle every other day uses, since only today can
/// ever actually be tapped.
class _WeekStrip extends StatelessWidget {
  final Set<DateTime> checkedDays;
  final bool checkedInToday;
  final VoidCallback onCheckIn;

  const _WeekStrip({required this.checkedDays, required this.checkedInToday, required this.onCheckIn});

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday % 7));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isToday = day == today;
        final isFuture = day.isAfter(today);

        return Column(
          children: [
            Text(
              _dayLabels[i],
              style: AppTypography.weight(
                TextStyle(fontSize: 11, color: isToday ? scheme.primary : scheme.onSurfaceVariant),
                isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            if (isToday)
              _TodayCheckInCircle(checkedIn: checkedInToday, onTap: onCheckIn)
            else
              _DayCircle(checked: checkedDays.contains(day), dimmed: isFuture),
          ],
        );
      }),
    );
  }
}

/// A past (or future-placeholder) day in the week strip -- the same
/// plain filled-circle-with-flame look this card has always used,
/// factored out now that today needs a genuinely different, animated
/// widget next to it.
class _DayCircle extends StatelessWidget {
  final bool checked;
  final bool dimmed;
  const _DayCircle({required this.checked, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: dimmed ? scheme.outlineVariant.withValues(alpha: 0.35) : scheme.outlineVariant,
        ),
      ),
      child: checked ? Icon(Icons.local_fire_department_rounded, size: 14, color: scheme.onPrimary) : null,
    );
  }
}

/// Today's slot in the week strip -- the one genuinely interactive
/// piece of the streak card, and the "copy games" ask: not checked in
/// yet, a soft pulsing glow invites the tap; tapped, a haptic buzz, a
/// bounce-overshoot scale on the circle itself, and a ring expanding
/// and fading outward give the daily check-in a small reward moment
/// instead of a state just silently flipping. Once checked in it
/// settles into the same plain look _DayCircle uses for past days and
/// stops being tappable -- there's nothing to undo to.
class _TodayCheckInCircle extends StatefulWidget {
  final bool checkedIn;
  final VoidCallback onTap;
  const _TodayCheckInCircle({required this.checkedIn, required this.onTap});

  @override
  State<_TodayCheckInCircle> createState() => _TodayCheckInCircleState();
}

class _TodayCheckInCircleState extends State<_TodayCheckInCircle> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _burstController;
  bool _justChecked = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.checkedIn) return;
    setState(() => _justChecked = true);
    unawaited(_burstController.forward(from: 0));
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final checked = widget.checkedIn;

    return Semantics(
      button: true,
      label: l10n.markTodayAsRead,
      child: GestureDetector(
        onTap: _handleTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding, fading burst ring -- plays once per tap, not
              // a continuous loop like the pulse below.
              AnimatedBuilder(
                animation: _burstController,
                builder: (context, child) {
                  final t = _burstController.value;
                  if (t == 0) return const SizedBox.shrink();
                  return Opacity(
                    opacity: 1.0 - t,
                    child: Transform.scale(
                      scale: 1.0 + t * 0.9,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.primary, width: 2),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Soft pulsing glow while not yet checked in, inviting the
              // tap -- stops the moment there's nothing left to draw the
              // eye toward, same reasoning as _FlickeringFlame.
              if (!checked)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(_pulseController.value);
                    return Container(
                      width: 28 + t * 6,
                      height: 28 + t * 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(alpha: 0.18 - t * 0.12),
                      ),
                    );
                  },
                ),
              AnimatedScale(
                scale: _justChecked ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.elasticOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked ? scheme.primary : Colors.transparent,
                    border: Border.all(color: scheme.primary, width: checked ? 1 : 2),
                  ),
                  child: Icon(
                    checked ? Icons.local_fire_department_rounded : Icons.add_rounded,
                    size: checked ? 14 : 16,
                    color: checked ? scheme.onPrimary : scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
