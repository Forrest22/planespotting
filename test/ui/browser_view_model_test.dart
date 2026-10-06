import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/ui/features/browser/view_models/browser_view_model.dart';

import '../support/test_data.dart';

Future<(BrowserViewModel, List<PlanechaseCard>)> makeViewModel() async {
  final cards = await loadedCardRepository();
  final settings = await loadedSettingsRepository(cards);
  return (BrowserViewModel(cardRepository: cards, settingsRepository: settings), cards.cards);
}

List<String> names(BrowserViewModel viewModel) => viewModel.entries.map((card) => card.name).toList();

void main() {
  test('search matches the name, rules text and artist, ignoring case', () async {
    final (viewModel, _) = await makeViewModel();
    expect(viewModel.entries, hasLength(5)); // everything, including the off-by-default Un-card

    viewModel.setQuery('ESPER');
    expect(names(viewModel), ['Esper']);
    viewModel.setQuery('artist of tardis'); // only in the artist credit
    expect(names(viewModel), ['TARDIS Bay']);
    viewModel.setQuery('text for amy');
    expect(names(viewModel), ["Amy's Home"]);
    viewModel.setQuery('no such card');
    expect(viewModel.entries, isEmpty);
  });

  test('set and type chips are OR within a group and AND across groups', () async {
    final (viewModel, _) = await makeViewModel();

    viewModel.toggleSet('who');
    expect(names(viewModel), ['TARDIS Bay', "Amy's Home"]);
    viewModel.toggleSet('moc');
    expect(viewModel.entries, hasLength(4));

    viewModel.toggleType(CardType.phenomenon);
    expect(names(viewModel), ['Chaotic Aether']);

    viewModel.toggleSet('moc'); // leaves only Doctor Who, which has no phenomena
    expect(viewModel.entries, isEmpty);
    expect(viewModel.hasActiveFilters, isTrue);

    viewModel.clearFilters();
    expect(viewModel.entries, hasLength(5));
    expect(viewModel.hasActiveFilters, isFalse);
  });

  test('excluding a card is saved, and the excluded-only filter lists it', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);
    final viewModel = BrowserViewModel(cardRepository: cards, settingsRepository: settings);
    final esper = cards.cards.first;

    expect(viewModel.isInPlay(esper), isTrue);
    await viewModel.toggleExcluded(esper);
    expect(settings.denylist, {'moc-49'});
    expect(viewModel.isExcluded(esper), isTrue);
    expect(viewModel.isInPlay(esper), isFalse);
    expect(viewModel.isHiddenByOptions(esper), isFalse); // excluded on its own, not by Options

    viewModel.setExcludedOnly(true);
    expect(names(viewModel), ['Esper']);

    await viewModel.toggleExcluded(esper);
    expect(settings.denylist, isEmpty);
    expect(viewModel.entries, isEmpty);
  });

  test('a card in a set that is off in Options is out of play, and such cards sort last', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);
    final viewModel = BrowserViewModel(cardRepository: cards, settingsRepository: settings);
    final bean = cards.cards.firstWhere((card) => card.set == 'punk'); // Un-sets default to off

    expect(viewModel.isHiddenByOptions(bean), isTrue);
    expect(viewModel.isInPlay(bean), isFalse);
    expect(viewModel.isExcluded(bean), isFalse);

    // Turning a set off moves its cards to the end, each group keeping its own order.
    await settings.setSetEnabled('moc', false);
    expect(names(viewModel), ['TARDIS Bay', "Amy's Home", 'Esper', 'Chaotic Aether', 'The Bean']);
  });

  test('bulk exclude and include act only on the cards now shown, in one notification', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);
    final viewModel = BrowserViewModel(cardRepository: cards, settingsRepository: settings);
    var notifications = 0;
    settings.addListener(() => notifications++);

    viewModel.toggleSet('who'); // shows TARDIS Bay and Amy's Home
    expect((viewModel.excludableCount, viewModel.includableCount), (2, 0));
    await viewModel.excludeShown();
    expect(settings.denylist, {'who-600', 'who-566'}); // nothing else touched
    expect(notifications, 1);
    expect((viewModel.excludableCount, viewModel.includableCount), (0, 2));

    viewModel.clearFilters();
    viewModel.setExcludedOnly(true);
    await viewModel.includeShown();
    expect(settings.denylist, isEmpty);
  });
}
