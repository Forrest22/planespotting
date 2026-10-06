import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

void main() {
  const json = {
    'name': 'Esper',
    'set': 'moc',
    'setName': 'March of the Machine Commander',
    'number': '49',
    'type': 'plane',
    'oracleText': 'Some text',
    'image': 'assets/cards/moc-49-esper.webp',
    'funny': false,
  };

  test('fromJson/toJson round-trip and expose the card id', () {
    final card = PlanechaseCard.fromJson(json);

    expect(card.id, 'moc-49');
    expect(card.toJson(), json);
  });

  test('fromJson throws FormatException for a missing or wrong-typed field', () {
    expect(() => PlanechaseCard.fromJson({...json}..remove('oracleText')), throwsFormatException);
    expect(() => PlanechaseCard.fromJson({...json, 'funny': 'no'}), throwsFormatException);
  });
}
