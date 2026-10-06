import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

import '../support/test_data.dart';

void main() {
  test('defaults to funny sets off, then loads saved values', () async {
    final cards = await loadedCardRepository();

    final defaults = await loadedSettingsRepository(cards);
    expect(defaults.enabledSets, {'moc', 'who'});
    expect(defaults.enabledTypes, CardType.values.toSet());

    final saved = await loadedSettingsRepository(cards, {
      'set_who': false,
      'set_punk': true,
      'type_phenomenon': false,
      'denylist': ['moc-49'],
    });
    expect(saved.enabledSets, {'moc', 'punk'});
    expect(saved.enabledTypes, {CardType.plane});
    expect(saved.denylist, {'moc-49'});
  });

  test('changes notify, persist across a reload, and can be undone', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.setSetEnabled('who', false);
    await settings.setTypeEnabled(CardType.phenomenon, false);
    await settings.setCardExcluded('moc-49', true);
    await settings.setCardExcluded('who-600', true);
    await settings.setCardExcluded('who-600', false);

    expect(notifications, 5);
    final reloaded = await loadedSettingsRepositoryFromExisting(cards);
    expect(reloaded.enabledSets, {'moc'});
    expect(reloaded.enabledTypes, {CardType.plane});
    expect(reloaded.denylist, {'moc-49'});
  });
}
