import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter's LicensePage auto-collects every pub.dev package's LICENSE
  // file, but the bundled Noto fonts are plain assets, not a package --
  // nothing registers their license automatically, so it's added here.
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.value(
      const LicenseEntryWithLineBreaks(['NotoSans', 'NotoSerif'], '''
Copyright 2022 The Noto Project Authors (https://github.com/notofonts/latin-greek-cyrillic)

This Font Software is licensed under the SIL Open Font License, Version 1.1.
See https://scripts.sil.org/OFL for the full license text.'''),
    );
  });

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
