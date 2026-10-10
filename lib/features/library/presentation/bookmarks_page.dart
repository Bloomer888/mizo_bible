import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../reader/data/verse_annotations_repository.dart';
import '../../reader/presentation/reader_page.dart';
import 'library_providers.dart';

final bookmarksListProvider = FutureProvider.autoDispose<List<BookmarkEntry>>((ref) async {
  final userDb = ref.watch(userDatabaseProvider);
  final names = await ref.watch(bookNamesMapProvider.future);
  return loadAllBookmarks(userDb, names);
});

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(bookmarksListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookmarks)),
      body: switch (itemsAsync) {
        AsyncData(:final value) when value.isEmpty => Center(child: Text(l10n.noBookmarksYet)),
        AsyncData(:final value) => ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, i) {
              final entry = value[i];
              return ListTile(
                leading: const Icon(Icons.bookmark),
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
