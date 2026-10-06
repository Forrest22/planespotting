import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/ui/features/options/views/options_screen.dart';

import '../support/test_data.dart';

Future<void> pumpOptions(WidgetTester tester) async {
  final cards = await loadedCardRepository();
  final settings = await loadedSettingsRepository(cards);
  await tester.pumpWidget(MaterialApp(
    home: OptionsScreen(cardRepository: cards, settingsRepository: settings),
  ));
}

void main() {
  testWidgets('shows the three sections with defaults applied', (tester) async {
    await pumpOptions(tester);

    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Un-cards'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('4 cards enabled'), findsOneWidget); // Sets: moc (2) + who (2)
    expect(find.text('0 cards enabled'), findsOneWidget); // Un-cards are off by default
    expect(find.text('5 cards enabled'), findsOneWidget); // Types: every card
  });

  testWidgets('Sets section lists counts and unchecking a set updates the total', (tester) async {
    await pumpOptions(tester);

    await tester.tap(find.text('Sets'));
    await tester.pumpAndSettle();

    expect(find.text('March of the Machine Commander (2)'), findsOneWidget);
    expect(find.text('Doctor Who (2)'), findsOneWidget);
    expect(find.text('4 cards enabled'), findsOneWidget);

    await tester.tap(find.text('Doctor Who (2)'));
    await tester.pumpAndSettle();

    expect(find.text('2 cards enabled'), findsOneWidget);
  });

  testWidgets('Select All turns every set in the section on or off', (tester) async {
    await pumpOptions(tester);
    await tester.tap(find.text('Un-cards'));
    await tester.pumpAndSettle();
    expect(find.text('0 cards enabled'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first); // "Select All" for Un-cards
    await tester.pumpAndSettle();

    expect(find.text('1 card enabled'), findsOneWidget);
  });
}
