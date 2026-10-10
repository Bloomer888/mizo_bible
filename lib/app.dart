import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/db/user_database.dart';
import 'core/env.dart';
import 'core/l10n_extension.dart';
import 'core/theme/app_theme.dart';
import 'features/reader/presentation/reader_page.dart';
import 'features/sync/data/sync_repository.dart';
import 'l10n/app_localizations.dart';

class MizoBibleApp extends ConsumerStatefulWidget {
  const MizoBibleApp({super.key});

  @override
  ConsumerState<MizoBibleApp> createState() => _MizoBibleAppState();
}

class _MizoBibleAppState extends ConsumerState<MizoBibleApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncIfSignedIn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncIfSignedIn();
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
      // Genesis (book id 1), hardcoded -- a real book/chapter picker is
      // Phase 6 navigation, not this first reader pass.
      home: const ReaderPage(bookId: 1),
    );
  }
}
