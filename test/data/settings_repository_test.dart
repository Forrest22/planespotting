import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

import '../support/test_data.dart';

void main() {
  test('defaults to funny sets off, then loads saved values', () async {
    final cards = await loadedCardRepository();

    final defaults = await loadedSettingsRepository(cards);
    expect(defaults.enabledSets, {'moc', 'who'});
    expect(defaults.enabledTypes, CardType.values.toSet());
    expect(defaults.keepScreenOn, isTrue);
    expect(defaults.autoPlaneswalk, isTrue);

    final saved = await loadedSettingsRepository(cards, {
      'set_who': false,
      'set_punk': true,
      'type_phenomenon': false,
      'denylist': ['moc-49'],
      'keep_screen_on': false,
      'auto_planeswalk': false,
    });
    expect(saved.enabledSets, {'moc', 'punk'});
    expect(saved.enabledTypes, {CardType.plane});
    expect(saved.denylist, {'moc-49'});
    expect(saved.keepScreenOn, isFalse);
    expect(saved.autoPlaneswalk, isFalse);
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

  test('clearExcluded empties the denylist, notifies, and persists', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards, {
      'denylist': ['moc-49', 'who-600'],
    });
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.clearExcluded();

    expect(settings.denylist, isEmpty);
    expect(notifications, 1);
    expect((await loadedSettingsRepositoryFromExisting(cards)).denylist, isEmpty);
  });
}
