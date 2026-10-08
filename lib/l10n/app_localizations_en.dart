// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mizo Bible';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get notes => 'Notes';

  @override
  String get highlights => 'Highlights';

  @override
  String get history => 'History';

  @override
  String get continueReading => 'Continue reading';

  @override
  String get readingModeParallel => 'Parallel';

  @override
  String get readingModeMizoOnly => 'Mizo only';

  @override
  String get readingModeEnglishOnly => 'English only';

  @override
  String get swapLanguageSides => 'Swap sides';

  @override
  String get oldTestament => 'Old Testament';

  @override
  String get newTestament => 'New Testament';
}
