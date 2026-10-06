import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/ui/features/options/views/options_screen.dart';

import '../support/test_data.dart';

Future<SettingsRepository> pumpOptions(WidgetTester tester) async {
  final cards = await loadedCardRepository();
  final settings = await loadedSettingsRepository(cards);
  await tester.pumpWidget(MaterialApp(
    home: OptionsScreen(cardRepository: cards, settingsRepository: settings),
  ));
  return settings;
}

void main() {
  testWidgets('shows the three sections with default counts', (tester) async {
    await pumpOptions(tester);

    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Un-cards'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('4 cards enabled'), findsOneWidget); // Sets: moc (2) + who (2)
    expect(find.text('0 cards enabled'), findsOneWidget); // Un-cards are off by default
    expect(find.text('5 cards enabled'), findsOneWidget); // Types: every card
  });

  testWidgets('unchecking a set updates the section total', (tester) async {
    await pumpOptions(tester);
    await tester.tap(find.text('Sets'));
    await tester.pumpAndSettle();
    expect(find.text('Doctor Who (2)'), findsOneWidget);

    await tester.tap(find.text('Doctor Who (2)'));
    await tester.pumpAndSettle();

    expect(find.text('2 cards enabled'), findsOneWidget);
  });

  testWidgets('excluded cards show a row that lowers the counts and can restore them all', (tester) async {
    final settings = await pumpOptions(tester);
    expect(find.text('Excluded cards'), findsNothing);

    await settings.setCardExcluded('moc-49', true);
    await tester.pumpAndSettle();

    expect(find.text('Excluded cards'), findsOneWidget);
    expect(find.text('1 card excluded individually'), findsOneWidget);
    expect(find.text('3 cards enabled'), findsOneWidget); // Sets: 4 minus the excluded one
    expect(find.text('4 cards enabled'), findsOneWidget); // Types: 5 minus the excluded one

    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();

    expect(settings.denylist, isEmpty);
    expect(find.text('Excluded cards'), findsNothing);
    expect(find.text('4 cards enabled'), findsOneWidget);
  });
}
