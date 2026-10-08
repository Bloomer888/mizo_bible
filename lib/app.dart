import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n_extension.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class MizoBibleApp extends StatelessWidget {
  const MizoBibleApp({super.key});

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
      home: const _StartupPage(),
    );
  }
}

/// Placeholder home. Replaced by the reader in phase 4.
class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: const Center(
        // Renders the two characters most likely to break on a device with
        // incomplete Latin Extended Additional coverage.
        child: Text('Pathian Lehkhabu Thianghlim — ṭhu, Ṭ', textScaler: TextScaler.linear(1.4)),
      ),
    );
  }
}
