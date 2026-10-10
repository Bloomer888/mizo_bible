import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../../core/widgets/entry_card.dart';
import '../../reader/data/verse_annotations_repository.dart';
import '../../reader/presentation/reader_page.dart';
import 'library_providers.dart';

final notesListProvider = FutureProvider.autoDispose<List<NoteEntry>>((ref) async {
  final userDb = ref.watch(userDatabaseProvider);
  final names = await ref.watch(bookNamesMapProvider.future);
  return loadAllNotes(userDb, names);
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(notesListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notes)),
      body: switch (itemsAsync) {
        AsyncData(:final value) when value.isEmpty =>
          EmptyState(icon: Icons.edit_note_rounded, message: l10n.noNotesYet),
        AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: value.length,
            itemBuilder: (context, i) {
              final entry = value[i];
              return EntryCard(
                icon: Icons.edit_note_rounded,
                title: '${entry.bookName} ${entry.chapter}:${entry.verse}',
                subtitle: entry.text,
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
