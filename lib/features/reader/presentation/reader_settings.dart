import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/db/user_database.dart';
import '../../../core/theme/app_typography.dart';

enum ReadingMode { parallel, mizoOnly, englishOnly }

/// Four styles from the two typefaces actually bundled with the app (see
/// app_typography.dart) -- condensed isn't a third font file, it's the same
/// two fonts' own `wdth` axis (confirmed present, 62.5-100, by reading each
/// file's fvar table directly) driven down from its 100 default. Not a
/// placeholder for more choices later; exactly these four exist because
/// that's what the two bundled variable fonts can actually produce.
enum ReaderFontFamily { sans, sansCondensed, serif, serifCondensed }

/// How condensed a "Condensed" style renders -- comfortably narrower than
/// the 100 default without nearing the 62.5 floor, where the bundled font
/// starts looking strained rather than just compact.
const _condensedWidth = 75.0;
const _regularWidth = 100.0;

extension ReaderFontFamilyX on ReaderFontFamily {
  String get familyName => switch (this) {
        ReaderFontFamily.sans || ReaderFontFamily.sansCondensed => AppTypography.sans,
        ReaderFontFamily.serif || ReaderFontFamily.serifCondensed => AppTypography.serif,
      };

  double get width => switch (this) {
        ReaderFontFamily.sans || ReaderFontFamily.serif => _regularWidth,
        ReaderFontFamily.sansCondensed || ReaderFontFamily.serifCondensed => _condensedWidth,
      };
}

const _settingsKey = 'reader_settings';

/// The slider's range -- a literal point size the user picks directly
/// (image the user supplied: a big number, a slider, +/- buttons, min/max
/// labels), not the old abstract 75-200% scale. 10 is "not super small"
/// per the user's own words (still legible, just small); 40 is this
/// session's judgment call for "not super large" after the user left the
/// exact ceiling to me ("maybe 40/50").
const minFontSize = 10.0;
const maxFontSize = 40.0;

/// What [ReaderSettings.scale] is 1.0 at -- the reader's chapter headers
/// and section headings (theme.textTheme.headlineMedium/titleMedium) still
/// scale via the old TextScaler mechanism in reader_page.dart, proportional
/// to the verse body text's own chosen size, so headings keep growing and
/// shrinking together with the body instead of needing their own sliders.
const _baseFontSize = 17.0;

const _minLineHeightScale = 0.9;
const _maxLineHeightScale = 2.0;
const _lineHeightStep = 0.1;

class ReaderSettings {
  final double fontSize;
  final double lineHeightScale;
  final ReadingMode mode;
  final bool swapped;
  final ReaderFontFamily fontFamily;

  const ReaderSettings({
    this.fontSize = _baseFontSize,
    this.lineHeightScale = 1.0,
    this.mode = ReadingMode.parallel,
    this.swapped = false,
    this.fontFamily = ReaderFontFamily.sans,
  });

  /// The multiplier reader_page.dart's page-wide TextScaler applies, so
  /// chapter headers and section headings scale in proportion to the body
  /// size chosen here rather than needing their own separate controls.
  double get scale => fontSize / _baseFontSize;

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeightScale,
    ReadingMode? mode,
    bool? swapped,
    ReaderFontFamily? fontFamily,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeightScale: lineHeightScale ?? this.lineHeightScale,
      mode: mode ?? this.mode,
      swapped: swapped ?? this.swapped,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineHeightScale': lineHeightScale,
        'mode': mode.name,
        'swapped': swapped,
        'fontFamily': fontFamily.name,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
        // No migration from the old 'fontScale' key -- a pre-launch,
        // single-test-device app with nothing durable to carry forward;
        // an old save just falls back to the new default, same as any
        // other corrupt-or-unrecognized value already does.
        fontSize: ((json['fontSize'] as num?)?.toDouble() ?? _baseFontSize).clamp(minFontSize, maxFontSize),
        lineHeightScale: (json['lineHeightScale'] as num?)?.toDouble() ?? 1.0,
        mode: ReadingMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ReadingMode.parallel,
        ),
        swapped: json['swapped'] as bool? ?? false,
        fontFamily: ReaderFontFamily.values.firstWhere(
          (f) => f.name == json['fontFamily'],
          orElse: () => ReaderFontFamily.sans,
        ),
      );
}

class ReaderSettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() {
    // Fires the async load without making build() itself async, so
    // every existing ref.watch(...select(...)) call site keeps working
    // unchanged -- state just starts at the default and updates once
    // the saved value (if any) has loaded, same tick or two after
    // first frame, not worth an AsyncNotifier's extra AsyncValue
    // wrapping everywhere this is read.
    _load();
    return const ReaderSettings();
  }

  Future<void> _load() async {
    final db = ref.read(userDatabaseProvider);
    final raw = await loadSetting(db, _settingsKey);
    if (raw == null) return;
    try {
      state = ReaderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or old-format value -- keep the default rather than crash.
    }
  }

  void _save() {
    final db = ref.read(userDatabaseProvider);
    // Best-effort, same reasoning as ReaderPage._saveCurrentPosition:
    // a save racing the database closing during teardown should never
    // throw into whatever's mid-unwind, just lose that one write.
    unawaited(saveSetting(db, _settingsKey, jsonEncode(state.toJson())).catchError((_) {}));
  }

  /// Drives the slider directly -- Slider.onChanged already only ever
  /// calls this with a value inside [minFontSize, maxFontSize] (it's the
  /// widget's own min/max), but the +/- buttons share this same setter and
  /// step past either end without the clamp, so it's enforced here once
  /// rather than at every call site.
  void setFontSize(double value) {
    state = state.copyWith(fontSize: value.clamp(minFontSize, maxFontSize));
    _save();
  }

  void increaseFontSize() => setFontSize(state.fontSize + 1);

  void decreaseFontSize() => setFontSize(state.fontSize - 1);

  void increaseLineHeight() {
    state = state.copyWith(
      lineHeightScale: (state.lineHeightScale + _lineHeightStep).clamp(_minLineHeightScale, _maxLineHeightScale),
    );
    _save();
  }

  void decreaseLineHeight() {
    state = state.copyWith(
      lineHeightScale: (state.lineHeightScale - _lineHeightStep).clamp(_minLineHeightScale, _maxLineHeightScale),
    );
    _save();
  }

  void setMode(ReadingMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void setFontFamily(ReaderFontFamily fontFamily) {
    state = state.copyWith(fontFamily: fontFamily);
    _save();
  }

  void toggleSwap() {
    state = state.copyWith(swapped: !state.swapped);
    _save();
  }
}

final readerSettingsProvider = NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(
  ReaderSettingsNotifier.new,
);
