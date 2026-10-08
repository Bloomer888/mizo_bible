import 'package:flutter/material.dart';

import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4E3D),
      brightness: brightness,
    );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    // Default every text style to the bundled font, so no string anywhere in
    // the app can fall back to a system font that lacks the Mizo alphabet.
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: AppTypography.sans),
      primaryTextTheme:
          base.primaryTextTheme.apply(fontFamily: AppTypography.sans),
    );
  }
}
