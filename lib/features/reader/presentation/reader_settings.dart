import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReadingMode { parallel, mizoOnly, englishOnly }

/// In-memory for now -- not yet persisted across app restarts. Saving
/// these belongs with Phase 7's local user.db (settings table), not a
/// one-off mechanism built just for this; "reopen lands on the same
/// verse" (the plan's related Phase 5 acceptance item) is deferred for
/// the same reason.
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
}

const _minFontScale = 0.75;
const _maxFontScale = 2.0;
const _minLineHeightScale = 0.9;
const _maxLineHeightScale = 2.0;
const _step = 0.1;

class ReaderSettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() => const ReaderSettings();

  void increaseFontScale() => state = state.copyWith(
        fontScale: (state.fontScale + _step).clamp(_minFontScale, _maxFontScale),
      );

  void decreaseFontScale() => state = state.copyWith(
        fontScale: (state.fontScale - _step).clamp(_minFontScale, _maxFontScale),
      );

  void increaseLineHeight() => state = state.copyWith(
        lineHeightScale: (state.lineHeightScale + _step).clamp(_minLineHeightScale, _maxLineHeightScale),
      );

  void decreaseLineHeight() => state = state.copyWith(
        lineHeightScale: (state.lineHeightScale - _step).clamp(_minLineHeightScale, _maxLineHeightScale),
      );

  void setMode(ReadingMode mode) => state = state.copyWith(mode: mode);

  void toggleSwap() => state = state.copyWith(swapped: !state.swapped);
}

final readerSettingsProvider = NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(
  ReaderSettingsNotifier.new,
);
