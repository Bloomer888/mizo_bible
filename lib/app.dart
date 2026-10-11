import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';
import 'core/db/user_database.dart';
import 'core/env.dart';
import 'core/l10n_extension.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/data/daily_verse_notifications.dart';
import 'features/premium/data/premium_providers.dart';
import 'features/sync/data/sync_repository.dart';
import 'l10n/app_localizations.dart';

class MizoBibleApp extends ConsumerStatefulWidget {
  const MizoBibleApp({super.key});

  @override
  ConsumerState<MizoBibleApp> createState() => _MizoBibleAppState();
}

class _MizoBibleAppState extends ConsumerState<MizoBibleApp> with WidgetsBindingObserver {
  late final ProviderSubscription<bool> _premiumSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncIfSignedIn();
    _applyNotificationState(ref.read(isPremiumProvider)).catchError((_) {});
    // listenManual, not ref.listen -- this needs to fire once at
    // startup regardless of build(), and keep firing for the rest of
    // the app's life, not just while some widget happens to be
    // watching isPremiumProvider in its build method.
    _premiumSubscription = ref.listenManual<bool>(isPremiumProvider, (previous, next) {
      if (previous != next) _applyNotificationState(next).catchError((_) {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _premiumSubscription.close();
    super.dispose();
  }

  // Best-effort and silent, same reasoning as _syncIfSignedIn: Premium
  // members who deny the OS notification prompt simply don't get the
  // reminder, same as anyone on a build without RevenueCat configured --
  // never a crash or a blocking dialog.
  Future<void> _applyNotificationState(bool isPremium) async {
    try {
      if (!isPremium) {
        await cancelAllDailyVerseNotifications();
        return;
      }
      final granted = await requestNotificationPermission();
      if (!granted) return;
      await scheduleDailyQuoteNotification();
      await scheduleVerseChangeNotification();
    } catch (_) {
      // Swallowed deliberately -- see doc comment above.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _syncIfSignedIn();
    // The verse-changed notification is one-shot, not a native repeat
    // (see its own doc comment in daily_verse_notifications.dart), so
    // it needs refreshing here to stay aligned with the next rotation
    // for anyone who keeps the app around across many resumes rather
    // than relaunching it. Cheap and idempotent -- always replaces the
    // same notification id, never stacks up duplicates.
    if (ref.read(isPremiumProvider)) {
      scheduleVerseChangeNotification().catchError((_) {});
    }
  }

  // Launch and resume only -- not a timer or a realtime subscription,
  // which would be real background-sync infrastructure this app
  // doesn't need yet. Best-effort and silent: an automatic sync
  // failing (no network, etc.) must never surface as an error the
  // reader has to deal with. The "Sync now" button in AccountPage is
  // where a real failure becomes visible, since that's an action the
  // user explicitly asked for.
  void _syncIfSignedIn() {
    if (!Env.hasSupabase) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (!ref.read(isPremiumProvider)) return;
    syncUserData(ref.read(userDatabaseProvider), user.id).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShell(),
    );
  }
}
