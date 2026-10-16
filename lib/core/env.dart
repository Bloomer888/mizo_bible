/// Build-time configuration, supplied with `--dart-define-from-file`.
///
/// Values live in `dart_define.json` (gitignored). See
/// `dart_define.example.json` for the expected shape, and README for the
/// run command.
///
/// Note on secrecy: the Supabase *publishable* key is designed to be shipped
/// in clients and is not a secret. What actually protects the data is
/// Row Level Security on every table (phase 7). Keeping it out of source is
/// hygiene -- so the repo stays portable and the project can be rotated or
/// swapped without a code change -- not a secret-management measure.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// True when both values were supplied at build time.
  ///
  /// The Bible is fully offline, so a missing or unreachable backend must
  /// never stop the app from starting -- it only disables sync and accounts.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// RevenueCat's Android *public* API key -- safe to ship in the client,
  /// same trust level as the Supabase publishable key above.
  static const revenueCatAndroidApiKey =
      String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');

  /// True once Play Console products + a RevenueCat project exist and this
  /// key is supplied. Until then, every Premium surface must behave as
  /// "not premium, feature unavailable" rather than erroring -- nothing
  /// about reading the Bible may ever depend on this being true.
  static bool get hasRevenueCat => revenueCatAndroidApiKey.isNotEmpty;

  /// The Google Cloud "Web application" OAuth client ID -- passed as
  /// `serverClientId` when initializing GoogleSignIn on Android (no
  /// Firebase/google-services.json needed, since this project doesn't use
  /// Firebase elsewhere). Supabase validates the ID token against this
  /// same client, so it must be registered as a Google provider client ID
  /// in the Supabase Dashboard too, not just here.
  static const googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// True once a real Google Cloud OAuth client exists and this value is
  /// supplied. Until then, "Continue with Google" must not appear at all
  /// -- same fail-closed shape as hasRevenueCat above, not a button that
  /// shows and then errors.
  static bool get hasGoogleSignIn => googleWebClientId.isNotEmpty;
}
