import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/db/user_database.dart';

enum ReadingMode { parallel, mizoOnly, englishOnly }

const _settingsKey = 'reader_settings';

class ReaderSettings {
  final double fontScale;
  final double lineHeightScale;
  final ReadingMode mode;
  final bool swapped;

  const ReaderSettings({
    this.fontScale = 1.0,
    this.lineHeightScale = 1.0,
    this.mode = ReadingMode.parallel,
    this.swapped = false,
  });

  ReaderSettings copyWith({
    double? fontScale,
    double? lineHeightScale,
    ReadingMode? mode,
    bool? swapped,
  }) {
    return ReaderSettings(
      fontScale: fontScale ?? this.fontScale,
      lineHeightScale: lineHeightScale ?? this.lineHeightScale,
      mode: mode ?? this.mode,
      swapped: swapped ?? this.swapped,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontScale': fontScale,
        'lineHeightScale': lineHeightScale,
        'mode': mode.name,
        'swapped': swapped,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
        lineHeightScale: (json['lineHeightScale'] as num?)?.toDouble() ?? 1.0,
        mode: ReadingMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ReadingMode.parallel,
        ),
        swapped: json['swapped'] as bool? ?? false,
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

  void toggleSwap() {
    state = state.copyWith(swapped: !state.swapped);
    _save();
  }
}

final readerSettingsProvider = NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(
  ReaderSettingsNotifier.new,
);
