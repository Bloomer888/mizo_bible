import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/reader/data/reading_progress_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('no saved progress returns null', () async {
    expect(await loadReadingProgress(db, 1), isNull);
  });

  test('saves and loads a position', () async {
    await saveReadingProgress(db, bookId: 1, chapter: 3, verse: 7);
    final position = await loadReadingProgress(db, 1);
    expect(position, (chapter: 3, verse: 7));
  });

  test('saving again for the same book updates in place rather than duplicating', () async {
    await saveReadingProgress(db, bookId: 1, chapter: 3, verse: 7);
    await saveReadingProgress(db, bookId: 1, chapter: 5, verse: 2);

    final rows = await db.select(db.readingProgress).get();
    expect(rows, hasLength(1));
    expect(await loadReadingProgress(db, 1), (chapter: 5, verse: 2));
  });

  test('different books get independent rows', () async {
    await saveReadingProgress(db, bookId: 1, chapter: 10, verse: 1);
    await saveReadingProgress(db, bookId: 2, chapter: 2, verse: 5);

    expect(await loadReadingProgress(db, 1), (chapter: 10, verse: 1));
    expect(await loadReadingProgress(db, 2), (chapter: 2, verse: 5));
  });
}
