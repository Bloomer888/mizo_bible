import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name, shown in the app bar and task switcher
  ///
  /// In en, this message translates to:
  /// **'Mizo-English Parallel Bible'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @bible.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get bible;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @yourBible.
  ///
  /// In en, this message translates to:
  /// **'Your Bible'**
  String get yourBible;

  /// No description provided for @startReadingPrompt.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t started reading yet'**
  String get startReadingPrompt;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start in Genesis'**
  String get startReading;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @verseOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get verseOfTheDay;

  /// No description provided for @readingStreak.
  ///
  /// In en, this message translates to:
  /// **'Reading streak'**
  String get readingStreak;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreak(int count);

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best: {days} days'**
  String bestStreak(int days);

  /// No description provided for @startStreakPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap today to start your streak'**
  String get startStreakPrompt;

  /// No description provided for @continueStreakPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap today to keep your streak going'**
  String get continueStreakPrompt;

  /// No description provided for @markTodayAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark today as read'**
  String get markTodayAsRead;

  /// No description provided for @readingModeParallel.
  ///
  /// In en, this message translates to:
  /// **'Parallel'**
  String get readingModeParallel;

  /// No description provided for @readingModeMizoOnly.
  ///
  /// In en, this message translates to:
  /// **'Mizo only'**
  String get readingModeMizoOnly;

  /// No description provided for @readingModeEnglishOnly.
  ///
  /// In en, this message translates to:
  /// **'English only'**
  String get readingModeEnglishOnly;

  /// No description provided for @swapLanguageSides.
  ///
  /// In en, this message translates to:
  /// **'Swap sides'**
  String get swapLanguageSides;

  /// No description provided for @fontStyleSans.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif'**
  String get fontStyleSans;

  /// No description provided for @fontStyleSansCondensed.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif Condensed'**
  String get fontStyleSansCondensed;

  /// No description provided for @fontStyleSerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontStyleSerif;

  /// No description provided for @fontStyleSerifCondensed.
  ///
  /// In en, this message translates to:
  /// **'Serif Condensed'**
  String get fontStyleSerifCondensed;

  /// No description provided for @fontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get fontStyle;

  /// No description provided for @oldTestament.
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// No description provided for @newTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @verse.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get verse;

  /// No description provided for @booksMizo.
  ///
  /// In en, this message translates to:
  /// **'Bu Hming'**
  String get booksMizo;

  /// No description provided for @chaptersMizo.
  ///
  /// In en, this message translates to:
  /// **'Bung'**
  String get chaptersMizo;

  /// No description provided for @verseMizo.
  ///
  /// In en, this message translates to:
  /// **'Chang'**
  String get verseMizo;

  /// No description provided for @textSettings.
  ///
  /// In en, this message translates to:
  /// **'Text Settings'**
  String get textSettings;

  /// No description provided for @bookNamesInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Book names in English'**
  String get bookNamesInEnglish;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @removeHighlight.
  ///
  /// In en, this message translates to:
  /// **'Remove highlight'**
  String get removeHighlight;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a note for this verse'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksYet;

  /// No description provided for @noHighlightsYet.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet'**
  String get noHighlightsYet;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t set up for this build yet. Bookmarks, highlights, notes, and history are still saved on this device.'**
  String get signInUnavailable;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to sync or access Premium features on this device.'**
  String get signOutConfirmation;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @cloudSyncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync isn\'t set up for this build. Bookmarks, highlights, notes, and history are still saved on this device.'**
  String get cloudSyncUnavailable;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Synced just now'**
  String get syncedJustNow;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @bibleTextSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Bible Text'**
  String get bibleTextSectionTitle;

  /// No description provided for @bibleTextRights.
  ///
  /// In en, this message translates to:
  /// **'Mizo: Mizo-English Parallel Bible (2010/2011/2015/2017), a product of the Christian Research Centre, Aizawl — rights confirmed for use in this app. English: King James Version blended with New King James Version, used by permission of Thomas Nelson. Full-text use of the English side is still pending written permission from the current rights holder, HarperCollins Christian Publishing.'**
  String get bibleTextRights;

  /// No description provided for @deleteMyData.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteMyData;

  /// No description provided for @deleteMyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all your data?'**
  String get deleteMyDataTitle;

  /// No description provided for @deleteMyDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your bookmarks, highlights, notes, reading history, and reading progress from this device, and everything except reading history (which is never uploaded) from our servers too, and signs you out. This can\'t be undone.'**
  String get deleteMyDataConfirmation;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @premiumTagline.
  ///
  /// In en, this message translates to:
  /// **'Sync your bookmarks, highlights, and notes across every device.'**
  String get premiumTagline;

  /// No description provided for @premiumHeadline.
  ///
  /// In en, this message translates to:
  /// **'Go further with Premium'**
  String get premiumHeadline;

  /// No description provided for @premiumFeatureSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get premiumFeatureSyncTitle;

  /// No description provided for @premiumFeatureReadingPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Structured plans to read through Scripture at your own pace.'**
  String get premiumFeatureReadingPlansDescription;

  /// No description provided for @premiumFeatureNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Notifications'**
  String get premiumFeatureNotificationsTitle;

  /// No description provided for @premiumFeatureNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'A daily verse reminder, plus an alert the moment a new one arrives.'**
  String get premiumFeatureNotificationsDescription;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// No description provided for @saveBadge.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String saveBadge(int percent);

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @continueWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Continue — {price}'**
  String continueWithPrice(String price);

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Premium member'**
  String get premiumActive;

  /// No description provided for @signInToSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Sign in to subscribe to Premium'**
  String get signInToSubscribe;

  /// No description provided for @syncRequiresPremium.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync is a Premium feature'**
  String get syncRequiresPremium;

  /// No description provided for @unlockSync.
  ///
  /// In en, this message translates to:
  /// **'Unlock sync'**
  String get unlockSync;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restoreSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Premium restored'**
  String get restoreSuccessful;

  /// No description provided for @restoreNoPurchasesFound.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found for this account'**
  String get restoreNoPurchasesFound;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'You\'re now a Premium member'**
  String get purchaseSuccessful;

  /// No description provided for @purchaseError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with that purchase. Please try again.'**
  String get purchaseError;

  /// No description provided for @premiumNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Premium isn\'t available right now. Please try again later.'**
  String get premiumNotAvailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @freeTrialThen.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial, then {price}'**
  String freeTrialThen(int days, String price);

  /// No description provided for @readingPlans.
  ///
  /// In en, this message translates to:
  /// **'Reading Plans'**
  String get readingPlans;

  /// No description provided for @readingPlan.
  ///
  /// In en, this message translates to:
  /// **'Reading Plan'**
  String get readingPlan;

  /// No description provided for @startPlan.
  ///
  /// In en, this message translates to:
  /// **'Start Plan'**
  String get startPlan;

  /// No description provided for @dayOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String dayOfTotal(int day, int total);

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @planComplete.
  ///
  /// In en, this message translates to:
  /// **'Plan complete!'**
  String get planComplete;

  /// No description provided for @wordOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Word of the Day'**
  String get wordOfTheDay;

  /// No description provided for @dailyDevotion.
  ///
  /// In en, this message translates to:
  /// **'Daily Devotion'**
  String get dailyDevotion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
