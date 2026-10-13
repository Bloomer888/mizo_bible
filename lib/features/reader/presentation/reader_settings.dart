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

class ReaderSettings {
  final double fontScale;
  final double lineHeightScale;
  final ReadingMode mode;
  final bool swapped;
  final ReaderFontFamily fontFamily;

  const ReaderSettings({
    this.fontScale = 1.0,
    this.lineHeightScale = 1.0,
    this.mode = ReadingMode.parallel,
    this.swapped = false,
    this.fontFamily = ReaderFontFamily.sans,
  });

  ReaderSettings copyWith({
    double? fontScale,
    double? lineHeightScale,
    ReadingMode? mode,
    bool? swapped,
    ReaderFontFamily? fontFamily,
  }) {
    return ReaderSettings(
      fontScale: fontScale ?? this.fontScale,
      lineHeightScale: lineHeightScale ?? this.lineHeightScale,
      mode: mode ?? this.mode,
      swapped: swapped ?? this.swapped,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontScale': fontScale,
        'lineHeightScale': lineHeightScale,
        'mode': mode.name,
        'swapped': swapped,
        'fontFamily': fontFamily.name,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
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

const _minFontScale = 0.75;
const _maxFontScale = 2.0;
const _minLineHeightScale = 0.9;
const _maxLineHeightScale = 2.0;
const _step = 0.1;

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

  void increaseFontScale() {
    state = state.copyWith(fontScale: (state.fontScale + _step).clamp(_minFontScale, _maxFontScale));
    _save();
  }

  void decreaseFontScale() {
    state = state.copyWith(fontScale: (state.fontScale - _step).clamp(_minFontScale, _maxFontScale));
    _save();
  }

  void increaseLineHeight() {
    state = state.copyWith(
      lineHeightScale: (state.lineHeightScale + _step).clamp(_minLineHeightScale, _maxLineHeightScale),
    );
    _save();
  }

  void decreaseLineHeight() {
    state = state.copyWith(
      lineHeightScale: (state.lineHeightScale - _step).clamp(_minLineHeightScale, _maxLineHeightScale),
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
