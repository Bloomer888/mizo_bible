import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';
import '../db/user_database.dart';

const _settingsKey = 'dark_mode';

/// Whether the app renders AppTheme.dark() instead of AppTheme.light() --
/// a plain on/off switch (More, above Account), not a third "follow
/// system" option, per the user's explicit ask. Same persisted-Notifier
/// shape as BookNameLanguageNotifier (book_language_settings.dart): state
/// starts at the default and updates a tick later once any saved value
/// has loaded, rather than making build() itself async.
class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final db = ref.read(userDatabaseProvider);
    final raw = await loadSetting(db, _settingsKey);
    if (raw == 'true') state = true;
  }

  void setDarkMode(bool value) {
    state = value;
    final db = ref.read(userDatabaseProvider);
    unawaited(saveSetting(db, _settingsKey, value.toString()).catchError((_) {}));
  }
}

final darkModeProvider = NotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);
