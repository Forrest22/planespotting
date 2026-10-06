import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

import '../support/test_data.dart';

void main() {
  test('sets lists each set once, in data order, with its funny flag', () async {
    final repository = await loadedCardRepository();

    expect(repository.sets.map((set) => set.code), ['moc', 'who', 'punk']);
    expect(repository.sets.map((set) => set.funny), [false, false, true]);
  });

  test('counts cards per set and per type', () async {
    final repository = await loadedCardRepository();

    expect(repository.countInSet('who'), 2);
    expect(repository.countOfType(CardType.phenomenon), 1);
  });

  group('filter', () {
    test('keeps only enabled sets and types', () async {
      final repository = await loadedCardRepository();

      final result = repository.filter(
        enabledSets: {'moc', 'who'},
        enabledTypes: {CardType.plane},
      );

      expect(result.map((card) => card.name), ['Esper', 'TARDIS Bay', 'Amy\'s Home']);
    });

    test('drops denylisted cards', () async {
      final repository = await loadedCardRepository();

      final result = repository.filter(
        enabledSets: {'moc', 'who'},
        enabledTypes: CardType.values.toSet(),
        denylist: {'moc-49', 'who-600'},
      );

      expect(result.map((card) => card.name), ['Chaotic Aether', 'Amy\'s Home']);
    });

    test('returns nothing when no set or no type is enabled', () async {
      final repository = await loadedCardRepository();

      expect(repository.filter(enabledSets: {}, enabledTypes: CardType.values.toSet()), isEmpty);
      expect(repository.filter(enabledSets: {'moc'}, enabledTypes: {}), isEmpty);
    });
  });
}
