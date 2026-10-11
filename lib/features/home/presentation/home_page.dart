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
              _HomeCard(
                icon: Icons.local_fire_department_rounded,
                label: l10n.readingStreak,
                value: l10n.dayStreak(streak),
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
/// the right thing.
class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _HomeCard({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
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
    );
  }
}

/// Deliberately shows both languages, not just English -- the app's
/// whole identity is the parallel text, and it's only three extra lines.
/// Tapping jumps straight to the verse in its full chapter context,
/// same destination the continue-reading card uses.
class _VerseOfTheDayCard extends StatelessWidget {
  final VerseOfTheDay verse;
  const _VerseOfTheDayCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReaderPage(bookId: verse.bookId, targetChapter: verse.chapter, targetVerse: verse.verse),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.verseOfTheDay.toUpperCase(),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(verse.englishText, style: const TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 6),
              Text(
                verse.mizoText,
                style: TextStyle(fontSize: 14, height: 1.4, fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Text(
                '${verse.bookName} ${verse.chapter}:${verse.verse}',
                style: TextStyle(fontWeight: FontWeight.w600, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
