// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mizo-English Parallel Bible';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get bible => 'Bible';

  @override
  String get more => 'More';

  @override
  String get yourBible => 'Your Bible';

  @override
  String get startReadingPrompt => 'You haven\'t started reading yet';

  @override
  String get startReading => 'Start in Genesis';

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
  String get verseOfTheDay => 'Verse of the Day';

  @override
  String get readingStreak => 'Reading streak';

  @override
  String dayStreak(int count) {
    return '$count day streak';
  }

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

  @override
  String get books => 'Books';

  @override
  String get chapters => 'Chapters';

  @override
  String get verse => 'Verse';

  @override
  String get textSettings => 'Text Settings';

  @override
  String get addBookmark => 'Add bookmark';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get highlight => 'Highlight';

  @override
  String get removeHighlight => 'Remove highlight';

  @override
  String get addNote => 'Add note';

  @override
  String get editNote => 'Edit note';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get noteHint => 'Write a note for this verse';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get noBookmarksYet => 'No bookmarks yet';

  @override
  String get noHighlightsYet => 'No highlights yet';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get noHistoryYet => 'No reading history yet';

  @override
  String get account => 'Account';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordEmailSent =>
      'Check your email for a password reset link';

  @override
  String get confirmEmailSent => 'Check your email to confirm your account';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get signOut => 'Sign out';

  @override
  String get needAnAccount => 'Need an account? Create one';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get cloudSyncUnavailable =>
      'Cloud sync isn\'t set up for this build. Bookmarks, highlights, notes, and history are still saved on this device.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncedJustNow => 'Synced just now';

  @override
  String get about => 'About';

  @override
  String get bibleTextSectionTitle => 'Bible Text';

  @override
  String get bibleTextRights =>
      'Mizo: Mizo-English Parallel Bible (2010/2011/2015/2017), a product of the Christian Research Centre, Aizawl — rights confirmed for use in this app. English: King James Version blended with New King James Version, used by permission of Thomas Nelson. Full-text use of the English side is still pending written permission from the current rights holder, HarperCollins Christian Publishing.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get deleteMyData => 'Delete my data';

  @override
  String get deleteMyDataTitle => 'Delete all your data?';

  @override
  String get deleteMyDataConfirmation =>
      'This permanently deletes your bookmarks, highlights, notes, reading history, and reading progress from this device, and everything except reading history (which is never uploaded) from our servers too, and signs you out. This can\'t be undone.';

  @override
  String get premium => 'Premium';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get premiumTagline =>
      'Sync your bookmarks, highlights, and notes across every device.';

  @override
  String get premiumActive => 'You\'re a Premium member';

  @override
  String get signInToSubscribe => 'Sign in to subscribe to Premium';

  @override
  String get syncRequiresPremium => 'Cloud sync is a Premium feature';

  @override
  String get unlockSync => 'Unlock sync';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoreSuccessful => 'Premium restored';

  @override
  String get restoreNoPurchasesFound =>
      'No previous purchases found for this account';

  @override
  String get purchaseSuccessful => 'You\'re now a Premium member';

  @override
  String get purchaseError =>
      'Something went wrong with that purchase. Please try again.';

  @override
  String get premiumNotAvailable =>
      'Premium isn\'t available right now. Please try again later.';

  @override
  String get retry => 'Retry';

  @override
  String freeTrialThen(int days, String price) {
    return '$days-day free trial, then $price';
  }
}
