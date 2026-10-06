import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/planespotting.dart';
import 'package:planespotting/routes.dart';

import '../support/test_data.dart';

void main() {
  testWidgets('shows a card from the enabled sets only', (tester) async {
    // Only one eligible card, so the pick is deterministic.
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards, {
      'set_moc': false,
      'set_who': true,
      'type_phenomenon': false,
      'denylist': ['who-566'],
    });

    await tester.pumpWidget(MaterialApp(
      home: PlaneschasingStartPage(cardRepository: cards, settingsRepository: settings),
    ));

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/cards/who-600.webp');
    expect(find.text('No cards match your options'), findsNothing);
  });

  testWidgets('shows an empty state with a link to Options when nothing matches', (tester) async {
    final cards = await loadedCardRepository([testCard('Esper', type: CardType.plane)]);
    final settings = await loadedSettingsRepository(cards, {'set_moc': false});

    await tester.pumpWidget(MaterialApp(
      routes: {optionsRoute: (context) => const Text('options page')},
      home: PlaneschasingStartPage(cardRepository: cards, settingsRepository: settings),
    ));

    expect(find.text('No cards match your options'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.text('Open Options'));
    await tester.pumpAndSettle();

    expect(find.text('options page'), findsOneWidget);
  });
}
