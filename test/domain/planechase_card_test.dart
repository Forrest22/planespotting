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

  test('fromJson parses every field', () {
    final card = PlanechaseCard.fromJson(json);

    expect(card.name, 'Esper');
    expect(card.type, CardType.plane);
    expect(card.funny, isFalse);
    expect(card.id, 'moc-49');
  });

  test('toJson round-trips', () {
    expect(PlanechaseCard.fromJson(json).toJson(), json);
  });

  test('fromJson throws FormatException when a field is missing', () {
    final bad = Map<String, dynamic>.of(json)..remove('oracleText');

    expect(() => PlanechaseCard.fromJson(bad), throwsFormatException);
  });

  test('fromJson throws FormatException when a field has the wrong type', () {
    final bad = Map<String, dynamic>.of(json)..['funny'] = 'no';

    expect(() => PlanechaseCard.fromJson(bad), throwsFormatException);
  });
}
