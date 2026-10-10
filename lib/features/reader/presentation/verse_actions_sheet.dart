import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../data/verse_annotations_repository.dart';

/// Keyed by (bookId, chapter, verse) -- autoDispose since there's no
/// reason to keep a verse's annotation state cached once its row has
/// scrolled off and nothing's watching it. Invalidated explicitly after
/// every mutation in this sheet, which is what makes the verse row
/// (watching the same provider) pick up the change immediately.
final verseAnnotationsProvider =
    FutureProvider.autoDispose.family<VerseAnnotations, (int, int, int)>((ref, key) {
  final db = ref.watch(userDatabaseProvider);
  return loadVerseAnnotations(db, bookId: key.$1, chapter: key.$2, verse: key.$3);
});

const highlightColors = <String, Color>{
  'yellow': Color(0xFFFFF59D),
  'green': Color(0xFFA5D6A7),
  'blue': Color(0xFF90CAF9),
  'pink': Color(0xFFF48FB1),
  'orange': Color(0xFFFFCC80),
};

void openVerseActions(
  BuildContext context, {
  required int bookId,
  required String bookName,
  required int chapter,
  required int verse,
  required String? mizoText,
  required String? englishText,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => VerseActionsSheet(
      bookId: bookId,
      bookName: bookName,
      chapter: chapter,
      verse: verse,
      mizoText: mizoText,
      englishText: englishText,
    ),
  );
}

class VerseActionsSheet extends ConsumerWidget {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String? mizoText;
  final String? englishText;

  const VerseActionsSheet({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.mizoText,
    required this.englishText,
  });

  (int, int, int) get _key => (bookId, chapter, verse);

  String get _shareText {
    final parts = [?mizoText, ?englishText];
    return '${parts.join('\n')}\n— $bookName $chapter:$verse';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationsAsync = ref.watch(verseAnnotationsProvider(_key));
    final l10n = context.l10n;
    final db = ref.watch(userDatabaseProvider);

    final annotations = switch (annotationsAsync) {
      AsyncData(:final value) => value,
      _ => VerseAnnotations.none,
    };

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$bookName $chapter:$verse', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          ListTile(
            leading: Icon(annotations.bookmarked ? Icons.bookmark : Icons.bookmark_border),
            title: Text(annotations.bookmarked ? l10n.removeBookmark : l10n.addBookmark),
            onTap: () async {
              await toggleBookmark(db, bookId: bookId, chapter: chapter, verse: verse);
              ref.invalidate(verseAnnotationsProvider(_key));
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.format_color_fill, color: Theme.of(context).iconTheme.color),
                const SizedBox(width: 24),
                for (final entry in highlightColors.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () async {
                        await setHighlight(db, bookId: bookId, chapter: chapter, verse: verse, color: entry.key);
                        ref.invalidate(verseAnnotationsProvider(_key));
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: CircleAvatar(
                        backgroundColor: entry.value,
                        radius: 14,
                        child: annotations.highlightColor == entry.key
                            ? const Icon(Icons.check, size: 16, color: Colors.black54)
                            : null,
                      ),
                    ),
                  ),
                if (annotations.highlightColor != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.removeHighlight,
                    onPressed: () async {
                      await removeHighlight(db, bookId: bookId, chapter: chapter, verse: verse);
                      ref.invalidate(verseAnnotationsProvider(_key));
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(annotations.hasNote ? l10n.editNote : l10n.addNote),
            onTap: () => _openNoteEditor(context, db, ref),
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(l10n.copy),
            onTap: () {
              Clipboard.setData(ClipboardData(text: _shareText));
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(l10n.share),
            onTap: () {
              Navigator.of(context).pop();
              SharePlus.instance.share(ShareParams(text: _shareText));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openNoteEditor(BuildContext context, UserDatabase db, WidgetRef ref) async {
    // Deliberately does NOT pop the sheet before this -- popping first
    // and then awaiting (even a fast DB read) left a real gap where the
    // sheet's context could already be unmounted by the time this
    // tried to use it, silently aborting on the context.mounted guard
    // below with no visible error: the sheet would just close and
    // nothing else would happen. Showing the dialog on top of the
    // still-open sheet keeps this context valid throughout, and the
    // sheet is popped only at the very end, once it's safe.
    final existing = await loadNoteText(db, bookId: bookId, chapter: chapter, verse: verse);
    if (!context.mounted) return;
    final l10n = context.l10n;
    final controller = TextEditingController(text: existing ?? '');

    // Cancel only dismisses the dialog, leaving the sheet open behind it
    // so the user can still pick a different action; Save/Delete close
    // both, since that action is now complete.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$bookName $chapter:$verse'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: InputDecoration(hintText: l10n.noteHint),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await deleteNote(db, bookId: bookId, chapter: chapter, verse: verse);
                ref.invalidate(verseAnnotationsProvider(_key));
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.deleteNote),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                await deleteNote(db, bookId: bookId, chapter: chapter, verse: verse);
              } else {
                await saveNote(db, bookId: bookId, chapter: chapter, verse: verse, text: text);
              }
              ref.invalidate(verseAnnotationsProvider(_key));
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
