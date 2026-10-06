import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

import '../support/test_data.dart';

void main() {
  test('defaults: normal sets and all types on, funny sets off', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);

    expect(settings.enabledSets, {'moc', 'who'});
    expect(settings.enabledTypes, CardType.values.toSet());
    expect(settings.denylist, isEmpty);
  });

  test('loads previously saved values', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards, {
      'set_who': false,
      'set_punk': true,
      'type_phenomenon': false,
      'denylist': ['moc-49'],
    });

    expect(settings.enabledSets, {'moc', 'punk'});
    expect(settings.enabledTypes, {CardType.plane});
    expect(settings.denylist, {'moc-49'});
  });

  test('changes notify listeners and persist across a reload', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.setSetEnabled('who', false);
    await settings.setTypeEnabled(CardType.phenomenon, false);
    await settings.setCardExcluded('moc-49', true);

    expect(notifications, 3);
    expect(settings.isSetEnabled('who'), isFalse);

    // A new repository over the same preferences sees the saved state.
    final reloaded = await loadedSettingsRepositoryFromExisting(cards);
    expect(reloaded.enabledSets, {'moc'});
    expect(reloaded.enabledTypes, {CardType.plane});
    expect(reloaded.denylist, {'moc-49'});
  });

  test('un-excluding a card removes it from the denylist', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards, {
      'denylist': ['moc-49', 'who-600'],
    });

    await settings.setCardExcluded('moc-49', false);

    expect(settings.denylist, {'who-600'});
  });
}
