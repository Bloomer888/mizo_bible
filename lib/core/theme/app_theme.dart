import 'package:flutter/material.dart';

import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  // Material 3's default TextTheme already varies weight by style --
  // titleMedium/titleSmall/labelLarge/labelMedium/labelSmall all come back
  // at w500, not w400. On a normal static-weight font that's enough on its
  // own, but on this app's variable NotoSans/NotoSerif (see
  // app_typography.dart's doc comment) a bare `fontWeight` never actually
  // selects a heavier glyph unless `fontVariations` drives the `wght` axis
  // too -- so every one of those styles was silently rendering at the same
  // visual weight everywhere they're used via Theme.of(context).textTheme.*
  // (reader_page's verse references, reader_settings_sheet's heading, and
  // more). This re-derives fontVariations from each style's own fontWeight
  // once, here, instead of needing every call site to remember to do it.
  static TextTheme _withVariableWeights(TextTheme theme) {
    TextStyle? fix(TextStyle? style) =>
        style?.copyWith(fontVariations: AppTypography.variations(style.fontWeight ?? FontWeight.w400));

    return theme.copyWith(
      displayLarge: fix(theme.displayLarge),
      displayMedium: fix(theme.displayMedium),
      displaySmall: fix(theme.displaySmall),
      headlineLarge: fix(theme.headlineLarge),
      headlineMedium: fix(theme.headlineMedium),
      headlineSmall: fix(theme.headlineSmall),
      titleLarge: fix(theme.titleLarge),
      titleMedium: fix(theme.titleMedium),
      titleSmall: fix(theme.titleSmall),
      bodyLarge: fix(theme.bodyLarge),
      bodyMedium: fix(theme.bodyMedium),
      bodySmall: fix(theme.bodySmall),
      labelLarge: fix(theme.labelLarge),
      labelMedium: fix(theme.labelMedium),
      labelSmall: fix(theme.labelSmall),
    );
  }

  static ThemeData _build(Brightness brightness) {
    // `vibrant` over Material 3's default tonal-spot algorithm -- the
    // default reads as muted/pastel at this seed's chroma, which is a
    // real part of why the app felt flat before any component theming
    // even comes into it.
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4E3D),
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final radius = BorderRadius.circular(16);

    return base.copyWith(
      // Default every text style to the bundled font, so no string anywhere
      // in the app can fall back to a system font that lacks the Mizo
      // alphabet. Wrapped in _withVariableWeights so that font actually
      // varies by weight too -- see its doc comment.
      textTheme: _withVariableWeights(base.textTheme.apply(fontFamily: AppTypography.sans)),
      primaryTextTheme: _withVariableWeights(base.primaryTextTheme.apply(fontFamily: AppTypography.sans)),

      scaffoldBackgroundColor: scheme.surface,

      appBarTheme: AppBarTheme(
        // surfaceContainerLow, not the stronger surfaceContainer -- a
        // softer, barely-tinted lift off the scaffold's plain surface,
        // same token cardTheme/bottomSheetTheme below already use.
        // surfaceTintColor is explicitly transparent (same reasoning as
        // those two) because otherwise scrolledUnderElevation blends
        // scheme.surfaceTint into this color once content scrolls
        // beneath the bar -- which is nearly always, reading a book --
        // so the bar would drift away from backgroundColor and away
        // from navigationBarTheme below, which has no such scroll-driven
        // tint to begin with. shadowColor is kept: a drop shadow on
        // scroll is a fine "lift" cue that doesn't change the bar's own
        // fill, unlike the tint did.
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 3,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontVariations: AppTypography.variations(FontWeight.w600),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      // Explicit, not left to NavigationBar's own M3 default
      // (ColorScheme.surfaceContainer) -- that default is what caused
      // the original top/bottom mismatch, since AppBarTheme above was
      // never using that same token. Pinning both to the same literal
      // color here is what actually guarantees they match, rather than
      // two independent defaults happening to agree.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          highlightColor: scheme.primary.withValues(alpha: 0.14),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 1,
          shadowColor: scheme.shadow.withValues(alpha: 0.35),
          textStyle: AppTypography.weight(const TextStyle(fontSize: 15.5), FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          textStyle: AppTypography.weight(const TextStyle(fontSize: 15.5), FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.weight(const TextStyle(), FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: 1, thickness: 1),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
