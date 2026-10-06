import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/ui/features/game/view_models/game_view_model.dart';

import '../support/test_data.dart';

void main() {
  test('a full pass has no repeats, and paging back and forth keeps the same cards', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards); // 4 eligible cards
    final viewModel = GameViewModel(cardRepository: cards, settingsRepository: settings, random: Random(1));

    for (var page = 1; page < 4; page++) {
      viewModel.onPageChanged(page);
    }
    final firstPass = viewModel.history.take(4).map((card) => card.id).toList();
    expect(firstPass.toSet(), hasLength(4));

    viewModel.onPageChanged(0);
    viewModel.onPageChanged(1);
    expect(viewModel.current!.id, firstPass[1]);
    expect(viewModel.canGoBack, isTrue);
  });

  test('refresh honours the denylist, and an empty deck reports no cards', () async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);
    final viewModel = GameViewModel(cardRepository: cards, settingsRepository: settings, random: Random(1));

    await settings.setCardExcluded('moc-49', true);
    viewModel.refresh();
    expect(viewModel.history.skip(1).map((card) => card.id), isNot(contains('moc-49')));

    final nothing = await loadedSettingsRepository(cards, {'set_moc': false, 'set_who': false});
    expect(GameViewModel(cardRepository: cards, settingsRepository: nothing).hasCards, isFalse);
  });
}
