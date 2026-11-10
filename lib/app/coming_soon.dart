import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Discreet notice for options that are already on screen but not built
/// yet. Replaces the previous notice instead of queueing after it.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).comingSoon),
        duration: const Duration(seconds: 2),
      ),
    );
}
