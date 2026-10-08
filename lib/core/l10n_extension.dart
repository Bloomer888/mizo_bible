import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

extension LocalizationsX on BuildContext {
  /// Localized strings for the current locale.
  ///
  /// The generated `AppLocalizations.of` is nullable because the delegate
  /// might not be registered. It always is -- `MizoBibleApp` registers it --
  /// so this exposes a non-null accessor and keeps `!` out of widget code.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
