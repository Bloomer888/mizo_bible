import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../../../core/widgets/entry_card.dart';
import '../../reader/data/reading_history_repository.dart';
import '../../reader/presentation/reader_page.dart';
import 'library_providers.dart';

final historyListProvider = FutureProvider.autoDispose<List<HistoryEntry>>((ref) async {
  final userDb = ref.watch(userDatabaseProvider);
  final names = await ref.watch(bookNamesMapProvider.future);
  return loadHistory(userDb, names);
});

final _dateFormat = DateFormat.yMMMd().add_jm();

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(historyListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: switch (itemsAsync) {
        AsyncData(:final value) when value.isEmpty =>
          EmptyState(icon: Icons.history_rounded, message: l10n.noHistoryYet),
        AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: value.length,
            itemBuilder: (context, i) {
              final entry = value[i];
              return EntryCard(
                icon: Icons.history_rounded,
                title: '${entry.bookName} ${entry.chapter}',
                subtitle: _dateFormat.format(entry.visitedAt),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderPage(bookId: entry.bookId, targetChapter: entry.chapter),
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
