import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/ui/features/options/views/options_screen.dart';

import '../support/test_data.dart';

void main() {
  testWidgets('shows the game switches and the deck total, which leads to the card browser', (tester) async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);
    await tester.pumpWidget(MaterialApp(
      home: OptionsScreen(cardRepository: cards, settingsRepository: settings),
    ));

    expect(find.text('Planeswalk automatically'), findsOneWidget);
    expect(find.text('4 cards in the deck'), findsOneWidget); // enabled sets and types combined

    await settings.setCardExcluded('moc-49', true);
    await tester.pumpAndSettle();
    expect(find.text('3 cards in the deck'), findsOneWidget);
  });
}
