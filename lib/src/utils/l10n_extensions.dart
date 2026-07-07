import 'package:flutter/widgets.dart';
import 'package:gta_app/l10n/generated/app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)`, e.g. `context.l10n.commonRetry`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
