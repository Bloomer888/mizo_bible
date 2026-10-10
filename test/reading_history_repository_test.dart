import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/reader/data/reading_history_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('empty history loads as an empty list', () async {
    expect(await loadHistory(db, const {}), isEmpty);
  });

  test('logs a visit and loads it back', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    final history = await loadHistory(db, {1: 'Genesis'});
    expect(history, hasLength(1));
    expect(history.single.bookName, 'Genesis');
    expect(history.single.chapter, 1);
  });

  test('repeating the same chapter does not flood the log', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 1);

    final rows = await db.select(db.readingHistory).get();
    expect(rows, hasLength(1));
  });

  test('visiting a different chapter logs a new entry, most recent first', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 2);

    final history = await loadHistory(db, {1: 'Genesis'});
    expect(history, hasLength(2));
    expect(history.first.chapter, 2);
  });

  test('revisiting an earlier chapter logs a fresh entry (not deduped globally)', () async {
    await logChapterVisit(db, bookId: 1, chapter: 1);
    await logChapterVisit(db, bookId: 1, chapter: 2);
    await logChapterVisit(db, bookId: 1, chapter: 1);

    final rows = await db.select(db.readingHistory).get();
    expect(rows, hasLength(3));
  });
}
