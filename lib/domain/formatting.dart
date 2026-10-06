/// Turns Scryfall mana/ability symbols into readable words,
/// e.g. `{CHAOS}` -> "Chaos", `{T}` -> "Tap", `{2}{W}` -> "2W".
String formatOracleText(String raw) {
  return raw.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
    return switch (match[1]!) {
      'CHAOS' => 'Chaos',
      'T' => 'Tap',
      final symbol => symbol,
    };
  });
}
