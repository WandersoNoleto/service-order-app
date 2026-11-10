import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/app/theme.dart';

void main() {
  const green = Color(0xFF508D6B);
  const blue = Color(0xFF2255AA);

  test('buttons use the exact brand color', () {
    expect(buildTheme(green).colorScheme.primary, green);
    expect(buildTheme(blue).colorScheme.primary, blue);
  });

  test('selected states use the brand container, not the grey secondary', () {
    final scheme = buildTheme(blue).colorScheme;
    expect(scheme.secondaryContainer, scheme.primaryContainer);
    expect(scheme.onSecondaryContainer, scheme.onPrimaryContainer);
  });

  test('text on brand color stays readable', () {
    expect(buildTheme(blue).colorScheme.onPrimary, Colors.white);
    expect(buildTheme(green).colorScheme.onPrimary, Colors.white);
    expect(buildTheme(const Color(0xFFFFE082)).colorScheme.onPrimary, Colors.black);
  });

  test('dark theme uses a lighter, readable tone of the brand', () {
    final dark = buildTheme(green, brightness: Brightness.dark);
    expect(dark.brightness, Brightness.dark);
    expect(
      dark.colorScheme.primary.computeLuminance(),
      greaterThan(green.computeLuminance()),
    );
    expect(
      dark.scaffoldBackgroundColor.computeLuminance(),
      lessThan(dark.colorScheme.surface.computeLuminance()),
    );
  });
}
