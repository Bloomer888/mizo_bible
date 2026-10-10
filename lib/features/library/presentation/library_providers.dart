import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../navigation/data/book_repository.dart';

/// Shared by every library list page (bookmarks/highlights/notes/
/// history) -- each needs book names to label its rows, and there's no
/// reason for four separate copies of the same book_names query.
final bookNamesMapProvider = FutureProvider.autoDispose<Map<int, String>>((ref) {
  final db = ref.watch(bibleDatabaseProvider);
  return loadBookNamesMap(db);
});
