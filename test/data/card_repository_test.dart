import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

import '../support/test_data.dart';

void main() {
  test('sets are listed once in data order, with counts', () async {
    final repository = await loadedCardRepository();

    expect(repository.sets.map((set) => set.code), ['moc', 'who', 'punk']);
    expect(repository.sets.map((set) => set.funny), [false, false, true]);
    expect(repository.countInSet('who'), 2);
    expect(repository.countOfType(CardType.phenomenon), 1);
  });

  test('filter applies sets, types and the denylist', () async {
    final repository = await loadedCardRepository();
    final allTypes = CardType.values.toSet();

    final planes = repository.filter(enabledSets: {'moc', 'who'}, enabledTypes: {CardType.plane});
    final withoutDenied = repository.filter(
      enabledSets: {'moc', 'who'},
      enabledTypes: allTypes,
      denylist: {'moc-49', 'who-600'},
    );

    expect(planes.map((card) => card.name), ['Esper', 'TARDIS Bay', 'Amy\'s Home']);
    expect(withoutDenied.map((card) => card.name), ['Chaotic Aether', 'Amy\'s Home']);
    expect(repository.filter(enabledSets: {}, enabledTypes: allTypes), isEmpty);
  });
}
