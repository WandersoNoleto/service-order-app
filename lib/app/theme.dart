import 'package:flutter/material.dart';

/// App theme built from the client's brand color (BRAND_COLOR, the
/// background of the app icon), in a light or dark version.
///
/// Material 3 normally turns the seed into its own tones, so buttons would
/// come out "close to" the brand. In the light theme the brand is used
/// as-is for the primary color; the dark theme uses the lighter tone
/// generated from it, which stays readable on dark surfaces. Selected
/// states (yes/no buttons, chips) use the brand's container tone instead of
/// the greyish secondary palette.
///
/// Screens are a tinted page with flat cards on top: [ColorScheme.surface]
/// is the card color and [ThemeData.scaffoldBackgroundColor] the page.
ThemeData buildTheme(
  Color brandColor, {
  Brightness brightness = Brightness.light,
}) {
  final isDark = brightness == Brightness.dark;
  final generated = ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: brightness,
    // Keeps the generated tones close to the brand instead of muting it.
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );

  // Neutral grays, not tinted by the brand: the page is always a tone apart
  // from the cards and bars on top of it, even when it has nothing to show.
  final page = isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8);
  final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
  final field = isDark ? const Color(0xFF2A2A2A) : page;

  final colorScheme = generated.copyWith(
    primary: isDark ? null : brandColor,
    onPrimary: isDark ? null : _readableOn(brandColor),
    secondaryContainer: generated.primaryContainer,
    onSecondaryContainer: generated.onPrimaryContainer,
    surface: card,
  );

  final hairline = BorderSide(color: colorScheme.outlineVariant, width: 0.5);
  const fieldRadius = BorderRadius.all(Radius.circular(10));

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: page,
    // Top bar blends with the page: Material 3 would tint it ("scrolled
    // under") whenever the list scrolls behind it.
    appBarTheme: AppBarTheme(
      backgroundColor: page,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: hairline,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field,
      border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: hairline),
      enabledBorder:
          OutlineInputBorder(borderRadius: fieldRadius, borderSide: hairline),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      isDense: true,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// White or black text, whichever reads better on [background].
Color _readableOn(Color background) =>
    background.computeLuminance() > 0.45 ? Colors.black : Colors.white;
