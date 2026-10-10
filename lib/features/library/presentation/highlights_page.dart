import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../reader/data/verse_annotations_repository.dart';
import '../../reader/presentation/reader_page.dart';
import '../../reader/presentation/verse_actions_sheet.dart' show highlightColors;
import 'library_providers.dart';

final highlightsListProvider = FutureProvider.autoDispose<List<HighlightEntry>>((ref) async {
  final userDb = ref.watch(userDatabaseProvider);
  final names = await ref.watch(bookNamesMapProvider.future);
  return loadAllHighlights(userDb, names);
});

class HighlightsPage extends ConsumerWidget {
  const HighlightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(highlightsListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.highlights)),
      body: switch (itemsAsync) {
        AsyncData(:final value) when value.isEmpty => Center(child: Text(l10n.noHighlightsYet)),
        AsyncData(:final value) => ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, i) {
              final entry = value[i];
              return ListTile(
                leading: CircleAvatar(backgroundColor: highlightColors[entry.color], radius: 12),
                title: Text('${entry.bookName} ${entry.chapter}:${entry.verse}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderPage(
                      bookId: entry.bookId,
                      targetChapter: entry.chapter,
                      targetVerse: entry.verse,
                    ),
                  ),
                ),
              );
            },
          ),
        AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
