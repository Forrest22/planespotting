import 'package:flutter/material.dart';

/// The app's theme: Material 3, seeded from deep purple, in light or dark.
ThemeData appTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: brightness);
  // M3's dark `primary` is a pale lavender, so dark mode uses the container to keep the bars deep purple.
  final (barColor, onBarColor) = brightness == Brightness.light
      ? (scheme.primary, scheme.onPrimary)
      : (scheme.primaryContainer, scheme.onPrimaryContainer);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(backgroundColor: barColor, foregroundColor: onBarColor),
  );
}
