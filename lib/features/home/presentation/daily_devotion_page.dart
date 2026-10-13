import 'package:flutter/material.dart';

import '../../../core/l10n_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../reader/presentation/reader_page.dart';
import '../data/daily_devotion.dart';

/// The full write-up for a Daily Devotion -- a plain article page, same
/// Scaffold+AppBar+ListView shape as about_page.dart, the only other
/// long-form text page in the app. The scripture reference is a
/// tappable row into the reader, same destination Verse of the Day and
/// the Reading Plan card both use already.
class DailyDevotionPage extends StatelessWidget {
  final DailyDevotion devotion;
  const DailyDevotionPage({super.key, required this.devotion});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final reference = devotion.verseEnd == null
        ? '${devotion.bookName} ${devotion.chapter}:${devotion.verseStart}'
        : '${devotion.bookName} ${devotion.chapter}:${devotion.verseStart}-${devotion.verseEnd}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dailyDevotion)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              devotion.title,
              style: AppTypography.weight(const TextStyle(fontSize: 22), FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderPage(
                    bookId: devotion.bookId,
                    targetChapter: devotion.chapter,
                    targetVerse: devotion.verseStart,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(reference, style: AppTypography.weight(TextStyle(color: scheme.primary), FontWeight.w600)),
                ],
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Text(devotion.body, style: const TextStyle(fontSize: 16, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
