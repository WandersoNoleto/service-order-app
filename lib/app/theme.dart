import 'package:flutter/material.dart';

/// App theme built from the client's brand color (BRAND_COLOR, the
/// background of the app icon).
///
/// Material 3 normally turns the seed into its own tones, so buttons would
/// come out "close to" the brand. Here the brand is used as-is for the
/// primary color, and selected states (bottom bar indicator, yes/no
/// buttons, chips) use the brand's container tone instead of the greyish
/// secondary palette.
ThemeData buildTheme(Color brandColor) {
  final generated = ColorScheme.fromSeed(
    seedColor: brandColor,
    // Keeps the generated tones close to the brand instead of muting it.
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );

  final colorScheme = generated.copyWith(
    primary: brandColor,
    onPrimary: _readableOn(brandColor),
    secondaryContainer: generated.primaryContainer,
    onSecondaryContainer: generated.onPrimaryContainer,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );
}

/// White or black text, whichever reads better on [background].
Color _readableOn(Color background) =>
    background.computeLuminance() > 0.45 ? Colors.black : Colors.white;
