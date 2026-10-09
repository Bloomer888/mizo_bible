import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n_extension.dart';
import 'core/theme/app_theme.dart';
import 'features/reader/presentation/reader_page.dart';
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
      // Genesis (book id 1), hardcoded -- a real book/chapter picker is
      // Phase 6 navigation, not this first reader pass.
      home: const ReaderPage(bookId: 1),
    );
  }
}
