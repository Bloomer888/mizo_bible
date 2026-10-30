import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/user_database.dart';
import '../../../core/env.dart';
import '../../../core/l10n_extension.dart';
import '../../premium/data/premium_providers.dart';
import '../../premium/presentation/paywall_page.dart';
import '../../sync/data/sync_repository.dart';
import '../data/auth_repository.dart';

class AccountPage extends ConsumerWidget {
  // True from the paywall's sign-in prompt specifically: once sign-in
  // succeeds, this page pops itself so the caller (PaywallPage, already
  // watching currentUserProvider) is immediately visible showing the
  // plans instead of leaving the user stranded here needing a manual
  // back-tap. False (the default) for the standalone More > Account
  // entry point, which should stay put after signing in -- that's
  // where "signed in as ..." and the rest of the account view live.
  final bool popOnSuccess;
  const AccountPage({super.key, this.popOnSuccess = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (!Env.hasSupabase) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.account)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.cloudSyncUnavailable, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: user == null ? _SignInForm(popOnSuccess: popOnSuccess) : _SignedInView(user: user),
    );
  }
}

class _SignedInView extends ConsumerStatefulWidget {
  final User user;
  const _SignedInView({required this.user});

  @override
  ConsumerState<_SignedInView> createState() => _SignedInViewState();
}

class _SignedInViewState extends ConsumerState<_SignedInView> {
  bool _isSyncing = false;
  String? _syncError;
  bool _justSynced = false;
  bool _isDeleting = false;

  Future<void> _sync() async {
    setState(() {
      _isSyncing = true;
      _syncError = null;
    });
    try {
      await syncUserData(ref.read(userDatabaseProvider), widget.user.id);
      if (mounted) setState(() => _justSynced = true);
    } catch (error) {
      if (mounted) setState(() => _syncError = error.toString());
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteMyDataTitle),
        content: Text(l10n.deleteMyDataConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    await deleteAllUserData(ref.read(userDatabaseProvider), widget.user.id);
    await signOut();
    // No further setState -- signOut's auth-state event rebuilds
    // AccountPage itself into the sign-in form, which unmounts this
    // widget; setting local state on the way out would be pointless.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPremium = ref.watch(isPremiumProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.signedInAs, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(widget.user.email ?? '', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          if (isPremium) ...[
            OutlinedButton.icon(
              onPressed: _isSyncing ? null : _sync,
              icon: _isSyncing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(l10n.syncNow),
            ),
            if (_justSynced && !_isSyncing) ...[
              const SizedBox(height: 8),
              Text(l10n.syncedJustNow, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_syncError != null) ...[
              const SizedBox(height: 8),
              Text(_syncError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ] else ...[
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage())),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(l10n.unlockSync),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.syncRequiresPremium,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: signOut, child: Text(l10n.signOut)),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isDeleting ? null : _confirmAndDelete,
            icon: _isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(l10n.deleteMyData),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}

/// Google on Android, Apple on iOS -- one button, platform-exclusive, never
/// both. No email/password path exists in this app at all (user's explicit
/// call, 2026-10-16: typing an email and inventing a password was friction
/// worth cutting entirely, not just de-emphasizing next to a social
/// button). Sign-in only ever happens here, at the moment of a Premium
/// purchase or a deliberate Account visit -- never for reading the Bible --
/// so there's no broader app flow depending on a password-based identity
/// existing.
class _SignInForm extends ConsumerStatefulWidget {
  final bool popOnSuccess;
  const _SignInForm({required this.popOnSuccess});

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _useApple => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _submit() => _useApple ? _submitApple() : _submitGoogle();

  Future<void> _submitApple() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await signInWithApple();
      final user = response.user;
      if (user != null) {
        await syncUserData(ref.read(userDatabaseProvider), user.id);
      }
      if (widget.popOnSuccess && response.session != null && mounted) {
        Navigator.of(context).pop();
      }
    } on SignInWithAppleAuthorizationException catch (error) {
      // canceled is a genuine user-initiated back-out, same as Google's
      // canceled code above -- not an error worth surfacing.
      if (error.code != AuthorizationErrorCode.canceled && mounted) {
        setState(() => _errorMessage = error.message);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await signInWithGoogle();
      final user = response.user;
      if (user != null) {
        await syncUserData(ref.read(userDatabaseProvider), user.id);
      }
      if (widget.popOnSuccess && response.session != null && mounted) {
        Navigator.of(context).pop();
      }
    } on GoogleSignInException catch (error) {
      // canceled is a genuine user-initiated back-out (tapped outside the
      // account picker, pressed back) -- not an error worth surfacing.
      if (error.code != GoogleSignInExceptionCode.canceled && mounted) {
        setState(() => _errorMessage = error.description ?? error.code.name);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      // Anything else (a platform-channel error during the token
      // authorization step, etc.) used to be swallowed silently here --
      // the account picker would complete but the screen never changed
      // and nothing told the user why. Surface it instead.
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Not hidden-then-nothing -- an explicit message, same pattern
    // AccountPage itself already uses one level up for !Env.hasSupabase.
    // There's no fallback sign-in method to show instead of this one.
    // Apple's native flow needs no dart-define client ID the way Google
    // does -- it's gated only by platform, never by Env.hasGoogleSignIn.
    if (!_useApple && !Env.hasGoogleSignIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.signInUnavailable, textAlign: TextAlign.center),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.signIn, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.premiumTagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 28),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_useApple ? Icons.apple : Icons.g_mobiledata_rounded, size: _useApple ? 22 : 28),
              label: Text(_useApple ? l10n.continueWithApple : l10n.continueWithGoogle),
            ),
          ],
        ),
      ),
    );
  }
}
