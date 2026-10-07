import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/ui/core/card_image.dart';
import 'package:planespotting/ui/core/card_text_panel.dart';
import 'package:planespotting/ui/features/browser/views/browser_screen.dart';

import '../support/test_data.dart';

Future<SettingsRepository> pumpBrowser(
  WidgetTester tester, {
  List<PlanechaseCard>? cardList,
  Size size = const Size(900, 1400),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final cards = await loadedCardRepository(cardList);
  final settings = await loadedSettingsRepository(cards);
  await tester.pumpWidget(MaterialApp(
    home: BrowserScreen(cardRepository: cards, settingsRepository: settings),
  ));
  return settings;
}

void main() {
  testWidgets('lists every card, and a tile can exclude and include its card', (tester) async {
    final settings = await pumpBrowser(tester);
    expect(find.byIcon(Icons.block), findsNWidgets(5));

    await tester.tap(find.byIcon(Icons.block).first);
    await tester.pumpAndSettle();

    expect(settings.denylist, {'moc-49'});
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.block), findsNWidgets(4));

    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(settings.denylist, isEmpty);
  });

  testWidgets('a set chip, the search box and Clear filters narrow and restore the grid', (tester) async {
    await pumpBrowser(tester);

    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Doctor Who')); // the sets come last in the row
    await tester.tap(find.widgetWithText(FilterChip, 'Doctor Who'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.block), findsNWidgets(2));
    expect(find.textContaining('2 cards'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tardis');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.block), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'no such card');
    await tester.pumpAndSettle();
    expect(find.text('No cards match'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.block), findsNWidgets(5));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('a card in a set that is off shows the hidden icon', (tester) async {
    await pumpBrowser(tester);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget); // The Bean, from the Un-set that is off by default
  });

  testWidgets('tapping a card opens it full screen with its text and artist, and can exclude it', (tester) async {
    final settings = await pumpBrowser(tester);

    await tester.tap(find.byType(CardImage).first);
    await tester.pumpAndSettle();

    final panel = find.byType(CardTextPanel);
    expect(find.descendant(of: panel, matching: find.text('Text for Esper')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('Illustrated by Artist of Esper')), findsOneWidget);

    await tester.tap(find.byTooltip('Exclude from game'));
    await tester.pumpAndSettle();
    expect(settings.denylist, {'moc-49'});
    expect(find.byTooltip('Include in game'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1500); // swipe to the next result
    await tester.pumpAndSettle();
    expect(find.descendant(of: panel, matching: find.text('Text for Chaotic Aether')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // and the arrow keys turn pages too
    await tester.pumpAndSettle();
    expect(find.descendant(of: panel, matching: find.text('Text for Esper')), findsOneWidget);
  });

  testWidgets('the deck sheet turns sets on and off, and restores excluded cards', (tester) async {
    final settings = await pumpBrowser(tester);
    expect(find.textContaining('4 cards in the deck'), findsOneWidget);

    await tester.tap(find.byTooltip('Deck settings'));
    await tester.pumpAndSettle();
    expect(find.text('4 cards enabled'), findsNWidgets(1)); // Sets: moc (2) + who (2)
    expect(find.text('0 cards enabled'), findsOneWidget); // Un-cards are off by default

    await tester.tap(find.text('Sets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doctor Who (2)'));
    await tester.pumpAndSettle();
    expect(find.text('2 cards in the deck'), findsOneWidget);

    await settings.setCardExcluded('moc-49', true);
    await tester.pumpAndSettle();
    expect(find.text('1 card excluded individually'), findsOneWidget);
    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();
    expect(settings.denylist, isEmpty);
    expect(find.text('Excluded cards'), findsNothing);
  });

  testWidgets('the filter chips list Included and Excluded only, then the types, then the sets', (tester) async {
    await pumpBrowser(tester);
    final labels = tester.widgetList<FilterChip>(find.byType(FilterChip)).map((chip) => (chip.label as Text).data);
    expect(labels.take(4), ['Included only', 'Excluded only', 'Planes', 'Phenomena']);
  });

  testWidgets('only the screen plus a few rows of tiles are built, wherever you scroll', (tester) async {
    final many = [for (var i = 0; i < 60; i++) testCard('Card $i', number: '$i')];
    await pumpBrowser(tester, cardList: many, size: const Size(400, 800));
    await tester.pumpAndSettle(); // the grid fills in a few rows per frame
    final tiles = find.byIcon(Icons.block);

    // Two columns; the screen shows about 3 rows and 3 more are preloaded, nowhere near all 60.
    expect(tiles.evaluate().length, inInclusiveRange(8, 24));
    expect(find.text('Card 0'), findsWidgets);
    expect(find.text('Card 59'), findsNothing);

    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(GridView), const Offset(0, -2000)); // to the very end
      await tester.pumpAndSettle();
    }
    expect(find.text('Card 59'), findsWidgets);

    expect(tiles.evaluate().length, inInclusiveRange(8, 24)); // still a window, not everything
    expect(find.text('Card 0'), findsNothing); // the first tiles were let go
  });

  testWidgets('each tile has a placeholder for its image to fade in over', (tester) async {
    await pumpBrowser(tester);
    expect(find.byKey(const ValueKey('image-placeholder')), findsNWidgets(5));
  });
}
