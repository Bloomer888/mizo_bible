import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../navigation/data/book_repository.dart';
import '../../navigation/presentation/book_language_settings.dart';

/// Shared by every library list page (bookmarks/highlights/notes) --
/// each needs book names to label its rows, and there's no reason for
/// three separate copies of the same book_names query.
final bookNamesMapProvider = FutureProvider.autoDispose<Map<int, String>>((ref) {
  final db = ref.watch(bibleDatabaseProvider);
  final language = ref.watch(bookNameLanguageProvider);
  return loadBookNamesMap(db, translationId: translationIdFor(language));
});
