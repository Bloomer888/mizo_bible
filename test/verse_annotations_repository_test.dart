import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/reader/data/verse_annotations_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a verse with no annotations loads as VerseAnnotations.none', () async {
    final result = await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1);
    expect(result.bookmarked, isFalse);
    expect(result.highlightColor, isNull);
    expect(result.hasNote, isFalse);
  });

  group('bookmarks', () {
    test('toggling on then off round-trips cleanly', () async {
      await toggleBookmark(db, bookId: 1, chapter: 1, verse: 1);
      expect((await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1)).bookmarked, isTrue);

      await toggleBookmark(db, bookId: 1, chapter: 1, verse: 1);
      expect((await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1)).bookmarked, isFalse);
    });

    test('toggling off and back on does not resurrect as a duplicate row', () async {
      await toggleBookmark(db, bookId: 1, chapter: 1, verse: 1);
      await toggleBookmark(db, bookId: 1, chapter: 1, verse: 1);
      await toggleBookmark(db, bookId: 1, chapter: 1, verse: 1);

      final rows = await db.select(db.bookmarks).get();
      expect(rows, hasLength(1));
      expect((await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1)).bookmarked, isTrue);
    });

    test('loadAllBookmarks excludes removed bookmarks and labels by book name', () async {
      await toggleBookmark(db, bookId: 1, chapter: 1, verse: 1);
      await toggleBookmark(db, bookId: 2, chapter: 3, verse: 5);
      await toggleBookmark(db, bookId: 2, chapter: 3, verse: 5); // removed again

      final entries = await loadAllBookmarks(db, {1: 'Genesis', 2: 'Exodus'});
      expect(entries, hasLength(1));
      expect(entries.single.bookName, 'Genesis');
      expect(entries.single.chapter, 1);
      expect(entries.single.verse, 1);
    });
  });

  group('highlights', () {
    test('set then remove round-trips cleanly', () async {
      await setHighlight(db, bookId: 1, chapter: 1, verse: 1, color: 'yellow');
      expect((await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1)).highlightColor, 'yellow');

      await removeHighlight(db, bookId: 1, chapter: 1, verse: 1);
      expect((await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1)).highlightColor, isNull);
    });

    test('setting a new color updates in place rather than duplicating', () async {
      await setHighlight(db, bookId: 1, chapter: 1, verse: 1, color: 'yellow');
      await setHighlight(db, bookId: 1, chapter: 1, verse: 1, color: 'blue');

      final rows = await db.select(db.highlights).get();
      expect(rows, hasLength(1));
      expect(rows.single.color, 'blue');
    });

    test('re-highlighting after removal reuses the row, not a fresh insert', () async {
      await setHighlight(db, bookId: 1, chapter: 1, verse: 1, color: 'yellow');
      await removeHighlight(db, bookId: 1, chapter: 1, verse: 1);
      await setHighlight(db, bookId: 1, chapter: 1, verse: 1, color: 'green');

      final rows = await db.select(db.highlights).get();
      expect(rows, hasLength(1));
      expect(rows.single.color, 'green');
      expect(rows.single.deleted, isFalse);
    });
  });

  group('notes', () {
    test('saves and loads note text', () async {
      await saveNote(db, bookId: 1, chapter: 1, verse: 1, text: 'A note.');
      expect(await loadNoteText(db, bookId: 1, chapter: 1, verse: 1), 'A note.');
      expect((await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1)).hasNote, isTrue);
    });

    test('saving again for the same verse updates in place', () async {
      await saveNote(db, bookId: 1, chapter: 1, verse: 1, text: 'First.');
      await saveNote(db, bookId: 1, chapter: 1, verse: 1, text: 'Second.');

      final rows = await db.select(db.notes).get();
      expect(rows, hasLength(1));
      expect(await loadNoteText(db, bookId: 1, chapter: 1, verse: 1), 'Second.');
    });

    test('deleting a note clears it', () async {
      await saveNote(db, bookId: 1, chapter: 1, verse: 1, text: 'Gone soon.');
      await deleteNote(db, bookId: 1, chapter: 1, verse: 1);

      expect(await loadNoteText(db, bookId: 1, chapter: 1, verse: 1), isNull);
      expect((await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1)).hasNote, isFalse);
    });

    test('writing again after deletion reuses the row, not a fresh insert', () async {
      // Same bug class as the bookmark toggle above: a delete-then-save
      // must revive the tombstoned row, not leave it behind and insert
      // a second one.
      await saveNote(db, bookId: 1, chapter: 1, verse: 1, text: 'First.');
      await deleteNote(db, bookId: 1, chapter: 1, verse: 1);
      await saveNote(db, bookId: 1, chapter: 1, verse: 1, text: 'Second.');

      final rows = await db.select(db.notes).get();
      expect(rows, hasLength(1));
      expect(rows.single.content, 'Second.');
      expect(rows.single.deleted, isFalse);
    });
  });

  test('loadVerseAnnotations combines all three independently for the same verse', () async {
    await toggleBookmark(db, bookId: 1, chapter: 1, verse: 1);
    await setHighlight(db, bookId: 1, chapter: 1, verse: 1, color: 'pink');
    await saveNote(db, bookId: 1, chapter: 1, verse: 1, text: 'All three at once.');

    final result = await loadVerseAnnotations(db, bookId: 1, chapter: 1, verse: 1);
    expect(result.bookmarked, isTrue);
    expect(result.highlightColor, 'pink');
    expect(result.hasNote, isTrue);
  });
}
