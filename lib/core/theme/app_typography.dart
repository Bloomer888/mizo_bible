import 'package:flutter/material.dart';

/// Weight handling for the bundled variable fonts.
///
/// NotoSans and NotoSerif are shipped as variable fonts with `wght` and `wdth`
/// axes, declared once each in pubspec.yaml. Flutter picks a font *asset* by
/// `fontWeight`, but with a single asset per family it cannot interpolate the
/// axis -- a `fontWeight: bold` alone renders at the font's default weight, or
/// gets a synthetic fake-bold. Driving the `wght` axis explicitly via
/// `fontVariations` is what actually produces real bold.
///
/// Always use [weight] rather than setting `fontWeight` by hand.
abstract final class AppTypography {
  static const sans = 'NotoSans';
  static const serif = 'NotoSerif';

  /// Sets both `fontWeight` (for Flutter's own layout decisions and for
  /// graceful fallback if the asset is ever missing) and the variable `wght`
  /// axis (which does the real work).
  static List<FontVariation> variations(FontWeight w) =>
      [FontVariation('wght', w.value.toDouble())];

  static TextStyle weight(TextStyle base, FontWeight w) =>
      base.copyWith(fontWeight: w, fontVariations: variations(w));
}
