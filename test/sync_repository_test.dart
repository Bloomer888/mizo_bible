import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/sync/data/sync_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Map<String, dynamic> remoteBookmark({
    required String id,
    required String userId,
    int bookId = 1,
    int chapter = 1,
    int verse = 1,
    bool deleted = false,
    String updatedAt = '2026-01-01T00:00:00.000Z',
  }) =>
      {
        'id': id,
        'user_id': userId,
        'book_id': bookId,
        'chapter': chapter,
        'verse': verse,
        'created_at': updatedAt,
        'updated_at': updatedAt,
        'deleted': deleted,
      };

  group('applyPulledBookmarks', () {
    test('inserts a remote row with no local match', () async {
      await applyPulledBookmarks(db, [remoteBookmark(id: 'remote-1', userId: 'u1')]);

      final rows = await db.select(db.bookmarks).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'remote-1');
      expect(rows.single.dirty, isFalse);
    });

    test('updates the same local row in place when ids already match', () async {
      await db.into(db.bookmarks).insert(
            BookmarksCompanion.insert(id: 'same-id', bookId: 1, chapter: 1, verse: 1, userId: const Value('u1')),
          );

      await applyPulledBookmarks(db, [remoteBookmark(id: 'same-id', userId: 'u1', deleted: true)]);

      final rows = await db.select(db.bookmarks).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'same-id');
      expect(rows.single.deleted, isTrue);
    });

    test('a different local row for the same verse is replaced, not duplicated', () async {
      // Simulates two devices independently bookmarking Genesis 1:1
      // before either had ever synced -- must converge on one row.
      await db.into(db.bookmarks).insert(
            BookmarksCompanion.insert(id: 'local-id', bookId: 1, chapter: 1, verse: 1, userId: const Value('u1')),
          );

      await applyPulledBookmarks(db, [remoteBookmark(id: 'remote-id', userId: 'u1')]);

      final rows = await db.select(db.bookmarks).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'remote-id');
    });

    test('a local row for a different verse is left untouched', () async {
      await db.into(db.bookmarks).insert(
            BookmarksCompanion.insert(id: 'other-verse', bookId: 2, chapter: 5, verse: 9, userId: const Value('u1')),
          );

      await applyPulledBookmarks(db, [remoteBookmark(id: 'remote-id', userId: 'u1', bookId: 1, chapter: 1, verse: 1)]);

      final rows = await db.select(db.bookmarks).get();
      expect(rows, hasLength(2));
    });
  });

  group('applyPulledReadingHistory', () {
    test('inserts remote entries without needing a business-key match', () async {
      await applyPulledReadingHistory(db, [
        {
          'id': 'h1',
          'user_id': 'u1',
          'book_id': 1,
          'chapter': 1,
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
          'deleted': false,
        },
      ]);

      final rows = await db.select(db.readingHistory).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'h1');
    });

    test('pulling the same entry twice does not duplicate it', () async {
      final entry = {
        'id': 'h1',
        'user_id': 'u1',
        'book_id': 1,
        'chapter': 1,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
        'deleted': false,
      };

      await applyPulledReadingHistory(db, [entry]);
      await applyPulledReadingHistory(db, [entry]);

      final rows = await db.select(db.readingHistory).get();
      expect(rows, hasLength(1));
    });
  });

  group('applyPulledSettings', () {
    test('converges on one row per key, adopting the remote id', () async {
      await db.into(db.settings).insert(
            SettingsCompanion.insert(id: 'local-id', key: 'theme', value: 'dark', userId: const Value('u1')),
          );

      await applyPulledSettings(db, [
        {
          'id': 'remote-id',
          'user_id': 'u1',
          'key': 'theme',
          'value': 'light',
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-02T00:00:00.000Z',
          'deleted': false,
        },
      ]);

      final rows = await db.select(db.settings).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'remote-id');
      expect(rows.single.value, 'light');
    });
  });

  group('applyPulledReadingProgress', () {
    test('converges on one row per book, adopting the remote id', () async {
      await db.into(db.readingProgress).insert(
            ReadingProgressCompanion.insert(id: 'local-id', bookId: 1, chapter: 2, verse: 3, userId: const Value('u1')),
          );

      await applyPulledReadingProgress(db, [
        {
          'id': 'remote-id',
          'user_id': 'u1',
          'book_id': 1,
          'chapter': 10,
          'verse': 20,
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-02T00:00:00.000Z',
          'deleted': false,
        },
      ]);

      final rows = await db.select(db.readingProgress).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'remote-id');
      expect(rows.single.chapter, 10);
    });
  });
}
