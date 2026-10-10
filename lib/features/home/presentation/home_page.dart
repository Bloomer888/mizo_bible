import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../library/presentation/library_providers.dart';
import '../../reader/data/reading_progress_repository.dart';
import '../../reader/presentation/reader_page.dart';

final _mostRecentProgressProvider = FutureProvider.autoDispose<BookReadingPosition?>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadMostRecentReadingProgress(db);
});

/// The Home tab -- deliberately just one thing: a way back into
/// whichever book you were last reading, or a nudge to start if you
/// haven't yet. Keeping this to a single clear card rather than a
/// dashboard of everything is the point, not an oversight.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progressAsync = ref.watch(_mostRecentProgressProvider);
    final namesAsync = ref.watch(bookNamesMapProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      // IntrinsicHeight, not just Align/Padding: this tab sits in the
      // shell's IndexedStack, and something in that chain (not fully
      // pinned down -- Align alone wasn't enough, despite Scaffold's
      // own body constraints already being loose) otherwise leaves the
      // card stretching to fill the tab's full height instead of
      // sizing to its own content. Forcing intrinsic sizing here is
      // the reliable fix regardless of the exact mechanism.
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: switch ((progressAsync, namesAsync)) {
              (AsyncData(value: final position?), AsyncData(:final value)) => _ContinueReadingCard(
                  bookName: value[position.bookId] ?? '',
                  bookId: position.bookId,
                  chapter: position.chapter,
                  verse: position.verse,
                ),
              (AsyncData(value: null), _) => const _StartReadingCard(),
              _ => const SizedBox.shrink(),
            },
          ),
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
