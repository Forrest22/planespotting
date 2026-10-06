import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/formatting.dart';

void main() {
  test('formatOracleText spells out symbols and keeps line breaks', () {
    expect(formatOracleText('Whenever you roll {CHAOS}, draw.\n{T}: add {2}{W}.'), 'Whenever you roll Chaos, draw.\nTap: add 2W.');
    expect(formatOracleText('No symbols here.'), 'No symbols here.');
  });
}
