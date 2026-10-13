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

  /// Returns [base] with its `wdth` axis (62.5-100 on both bundled fonts --
  /// confirmed by reading each file's own fvar table directly, not assumed)
  /// set to [width], preserving whatever `wght` variation [base] already
  /// carries. Replacing fontVariations outright instead of merging into it
  /// would silently drop that weight axis, the same mistake [weight]'s own
  /// doc comment exists to prevent in the first place.
  ///
  /// Nullable in and out, unlike [weight] -- its real call sites are always
  /// a literal TextStyle(...), but this one's are theme.textTheme.*?.copyWith(...)
  /// chains, which are nullable by nature.
  static TextStyle? width(TextStyle? base, double width) {
    if (base == null) return null;
    final kept = base.fontVariations?.where((v) => v.axis != 'wdth') ?? const <FontVariation>[];
    return base.copyWith(fontVariations: [...kept, FontVariation('wdth', width)]);
  }
}
