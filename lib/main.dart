import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The Bible is fully offline and free, so startup must never depend on the
  // network or on Supabase being reachable. A failure here disables sync and
  // accounts; it must not stop someone from reading.
  if (Env.hasSupabase) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabasePublishableKey,
      );
    } catch (error, stackTrace) {
      debugPrint('Supabase init failed; continuing offline: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: MizoBibleApp()));
}
