import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/user_database.dart';
import '../../../core/env.dart';
import '../../../core/l10n_extension.dart';
import '../../sync/data/sync_repository.dart';
import '../data/auth_repository.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

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
      body: user == null ? const _SignInForm() : _SignedInView(user: user),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.signedInAs, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(widget.user.email ?? '', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          FilledButton(onPressed: signOut, child: Text(l10n.signOut)),
        ],
      ),
    );
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final response = _isSignUp
          ? await signUp(email: email, password: password)
          : await signIn(email: email, password: password);

      final user = response.user;
      if (user != null) {
        await syncUserData(ref.read(userDatabaseProvider), user.id);
      }

      // Sign-up with email confirmation required returns a user but no
      // session yet -- currentUserProvider stays null until the link is
      // clicked and the user signs in for real, so this is the only
      // feedback they'd otherwise get that anything happened at all.
      if (_isSignUp && response.session == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.confirmEmailSent)));
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _errorMessage = l10n.invalidEmail);
      return;
    }
    try {
      await resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetPasswordEmailSent)));
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isSignUp ? l10n.createAccount : l10n.signIn, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(labelText: l10n.email),
              validator: (value) => (value == null || !value.contains('@')) ? l10n.invalidEmail : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password),
              validator: (value) => (value == null || value.length < 6) ? l10n.passwordTooShort : null,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? l10n.createAccount : l10n.signIn),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      }),
              child: Text(_isSignUp ? l10n.alreadyHaveAccount : l10n.needAnAccount),
            ),
            if (!_isSignUp)
              TextButton(
                onPressed: _isSubmitting ? null : _resetPassword,
                child: Text(l10n.forgotPassword),
              ),
          ],
        ),
      ),
    );
  }
}
