import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/l10n_extension.dart';
import '../../../core/widgets/entry_card.dart';
import '../../reader/presentation/reader_page.dart';
import '../data/search_repository.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchResultsProvider = FutureProvider.autoDispose<List<SearchResult>>((ref) {
  final db = ref.watch(bibleDatabaseProvider);
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Future.value(const []);
  return searchVerses(db, query);
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: l10n.search, border: InputBorder.none),
          onChanged: _onChanged,
        ),
      ),
      body: switch (resultsAsync) {
        AsyncData() when query.trim().isEmpty => const SizedBox.shrink(),
        AsyncData(:final value) when value.isEmpty =>
          EmptyState(icon: Icons.search_off_rounded, message: l10n.noResults),
        AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: value.length,
            itemBuilder: (context, i) => _ResultTile(result: value[i]),
          ),
        AsyncError(:final error) => Center(child: Text('Failed to search: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return EntryCard(
      icon: Icons.menu_book_rounded,
      title: '${result.bookName} ${result.chapter}:${result.verse}',
      subtitle: result.text,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReaderPage(
              bookId: result.bookId,
              targetChapter: result.chapter,
              targetVerse: result.verse,
            ),
          ),
        );
      },
    );
  }
}
