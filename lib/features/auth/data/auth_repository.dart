import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/user_database.dart';
import '../../../core/env.dart';
import '../../premium/data/premium_repository.dart';

/// Every auth event (sign in, sign out, token refresh). supabase_flutter
/// persists the session to disk itself and restores it before this
/// stream's first event, so a cold start that was previously signed in
/// comes up already-signed-in, not signed-out-then-in.
///
/// Same Env.hasSupabase guard as customerInfoProvider in
/// premium_providers.dart -- Supabase.instance throws if main() never
/// called Supabase.initialize (no credentials configured), and reading
/// a signed-out user must fail closed, not crash whatever screen
/// happens to watch this first.
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!Env.hasSupabase) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// `auth.currentUser` is already the always-current source of truth
/// (GoTrueClient keeps it updated independently of listeners) -- watching
/// authStateProvider here is only to make this provider rebuild on every
/// auth event, not to source the value itself.
final currentUserProvider = Provider<User?>((ref) {
  if (!Env.hasSupabase) return null;
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

/// GoogleSignIn.instance is already initialized at app startup (see
/// main.dart) -- this just drives one authenticate round-trip and hands
/// the resulting ID token to Supabase. The only sign-in path in this app
/// -- see account_page.dart's doc comment on _SignInForm for why there's
/// no email/password alternative. `authenticate()` itself throws
/// (including on user cancellation), so this has no special cancellation
/// handling of its own -- callers already catch broadly around sign-in
/// attempts.
Future<AuthResponse> signInWithGoogle() async {
  final googleUser = await GoogleSignIn.instance.authenticate();

  const scopes = ['email', 'profile'];
  final authorization = await googleUser.authorizationClient.authorizationForScopes(scopes) ??
      await googleUser.authorizationClient.authorizeScopes(scopes);

  final idToken = googleUser.authentication.idToken;
  if (idToken == null) {
    throw const AuthException('Google sign-in did not return an ID token.');
  }

  final response = await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: authorization.accessToken,
  );
  final user = response.user;
  if (user != null) await linkPremiumIdentity(user.id);
  return response;
}

Future<void> signOut() async {
  await unlinkPremiumIdentity();
  await Supabase.instance.client.auth.signOut();
}

/// Attaches every not-yet-claimed local row (userId still null -- created
/// before any sign-in existed) to the account that just signed in, so a
/// year of offline notes made before creating an account is adopted by
/// it instead of orphaned. Scoped to `userId IS NULL` specifically, not
/// a blanket update -- a row that already carries a (different) user's
/// id, which shouldn't happen on a single local database but isn't this
/// function's business to overwrite if it somehow did, is left alone.
Future<void> claimLocalRows(UserDatabase db, String userId) {
  return db.transaction(() async {
    await (db.update(db.bookmarks)..where((t) => t.userId.isNull()))
        .write(BookmarksCompanion(userId: Value(userId)));
    await (db.update(db.highlights)..where((t) => t.userId.isNull()))
        .write(HighlightsCompanion(userId: Value(userId)));
    await (db.update(db.notes)..where((t) => t.userId.isNull()))
        .write(NotesCompanion(userId: Value(userId)));
    await (db.update(db.readingHistory)..where((t) => t.userId.isNull()))
        .write(ReadingHistoryCompanion(userId: Value(userId)));
    await (db.update(db.readingProgress)..where((t) => t.userId.isNull()))
        .write(ReadingProgressCompanion(userId: Value(userId)));
    await (db.update(db.settings)..where((t) => t.userId.isNull()))
        .write(SettingsCompanion(userId: Value(userId)));
  });
}
