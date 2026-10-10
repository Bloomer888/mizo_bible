import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/auth/data/auth_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('claimLocalRows stamps every unclaimed row across all six tables', () async {
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(id: 'b1', bookId: 1, chapter: 1, verse: 1));
    await db.into(db.highlights).insert(
          HighlightsCompanion.insert(id: 'h1', bookId: 1, chapter: 1, verse: 1, color: 'yellow'),
        );
    await db.into(db.notes).insert(
          NotesCompanion.insert(id: 'n1', bookId: 1, chapter: 1, verse: 1, content: 'hi'),
        );
    await db.into(db.readingHistory).insert(ReadingHistoryCompanion.insert(id: 'rh1', bookId: 1, chapter: 1));
    await db.into(db.readingProgress).insert(
          ReadingProgressCompanion.insert(id: 'rp1', bookId: 1, chapter: 1, verse: 1),
        );
    await db.into(db.settings).insert(SettingsCompanion.insert(id: 's1', key: 'k', value: 'v'));

    await claimLocalRows(db, 'user-123');

    expect((await db.select(db.bookmarks).getSingle()).userId, 'user-123');
    expect((await db.select(db.highlights).getSingle()).userId, 'user-123');
    expect((await db.select(db.notes).getSingle()).userId, 'user-123');
    expect((await db.select(db.readingHistory).getSingle()).userId, 'user-123');
    expect((await db.select(db.readingProgress).getSingle()).userId, 'user-123');
    expect((await db.select(db.settings).getSingle()).userId, 'user-123');
  });

  test('claimLocalRows never reassigns a row that already belongs to someone else', () async {
    await db.into(db.bookmarks).insert(
          BookmarksCompanion.insert(id: 'b1', bookId: 1, chapter: 1, verse: 1, userId: const Value('someone-else')),
        );
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(id: 'b2', bookId: 2, chapter: 1, verse: 1));

    await claimLocalRows(db, 'user-123');

    final rows = {for (final r in await db.select(db.bookmarks).get()) r.id: r.userId};
    expect(rows['b1'], 'someone-else');
    expect(rows['b2'], 'user-123');
  });

  test('claiming twice with the same user is harmless', () async {
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(id: 'b1', bookId: 1, chapter: 1, verse: 1));

    await claimLocalRows(db, 'user-123');
    await claimLocalRows(db, 'user-123');

    final rows = await db.select(db.bookmarks).get();
    expect(rows, hasLength(1));
    expect(rows.single.userId, 'user-123');
  });
}
