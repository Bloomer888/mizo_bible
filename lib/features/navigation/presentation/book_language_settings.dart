import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/db/user_database.dart';
import '../../../l10n/app_localizations.dart';
import '../data/book_repository.dart';

/// Which language the book/chapter/verse navigation chrome (book list,
/// the book/chapter/verse picker, and labels built from them elsewhere --
/// bookmark/highlight/note rows, the reading plan card on Home) reads in.
/// Mizo by default, the user's explicit call; switching to English lives
/// as a single toggle on the More page. Never affects the reader's own
/// verse text, which always shows both languages regardless.
enum BookNameLanguage { mizo, english }

const _settingsKey = 'book_name_language';

String translationIdFor(BookNameLanguage language) => switch (language) {
      BookNameLanguage.mizo => mizoNavigationTranslationId,
      BookNameLanguage.english => englishNavigationTranslationId,
    };

extension BookNameLanguageLabels on BookNameLanguage {
  String booksLabel(AppLocalizations l10n) => this == BookNameLanguage.english ? l10n.books : l10n.booksMizo;
  String chaptersLabel(AppLocalizations l10n) => this == BookNameLanguage.english ? l10n.chapters : l10n.chaptersMizo;
  String verseLabel(AppLocalizations l10n) => this == BookNameLanguage.english ? l10n.verse : l10n.verseMizo;
}

class BookNameLanguageNotifier extends Notifier<BookNameLanguage> {
  @override
  BookNameLanguage build() {
    // Same reasoning as ReaderSettingsNotifier (reader_settings.dart):
    // fire the load without an async build(), so state just starts at
    // the default and updates a tick later once any saved value loads.
    _load();
    return BookNameLanguage.mizo;
  }

  Future<void> _load() async {
    final db = ref.read(userDatabaseProvider);
    final raw = await loadSetting(db, _settingsKey);
    if (raw == BookNameLanguage.english.name) state = BookNameLanguage.english;
  }

  void setLanguage(BookNameLanguage language) {
    state = language;
    final db = ref.read(userDatabaseProvider);
    unawaited(saveSetting(db, _settingsKey, language.name).catchError((_) {}));
  }
}

final bookNameLanguageProvider = NotifierProvider<BookNameLanguageNotifier, BookNameLanguage>(
  BookNameLanguageNotifier.new,
);
