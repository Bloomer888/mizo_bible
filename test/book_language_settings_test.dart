import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/features/navigation/data/book_repository.dart';
import 'package:mizo_bible/features/navigation/presentation/book_language_settings.dart';
import 'package:mizo_bible/l10n/app_localizations_en.dart';

/// translationIdFor and the label extension are the one piece of this
/// feature actually worth a test: pure mappings with no DB involved,
/// but exactly the kind of thing that's trivial to get backwards (Mizo
/// and English swapped) and would silently show the wrong language
/// rather than fail loudly.
void main() {
  final l10n = AppLocalizationsEn();

  test('translationIdFor maps each language to its own translation', () {
    expect(translationIdFor(BookNameLanguage.mizo), mizoNavigationTranslationId);
    expect(translationIdFor(BookNameLanguage.english), englishNavigationTranslationId);
    expect(mizoNavigationTranslationId, isNot(englishNavigationTranslationId));
  });

  test('Mizo is the default label set', () {
    expect(BookNameLanguage.mizo.booksLabel(l10n), l10n.booksMizo);
    expect(BookNameLanguage.mizo.chaptersLabel(l10n), l10n.chaptersMizo);
    expect(BookNameLanguage.mizo.verseLabel(l10n), l10n.verseMizo);
  });

  test('English picks the plain English labels', () {
    expect(BookNameLanguage.english.booksLabel(l10n), l10n.books);
    expect(BookNameLanguage.english.chaptersLabel(l10n), l10n.chapters);
    expect(BookNameLanguage.english.verseLabel(l10n), l10n.verse);
  });
}
