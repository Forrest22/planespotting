import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/ui/features/game/views/game_screen.dart';

import '../support/test_data.dart';

Future<void> pumpGame(WidgetTester tester) async {
  final cards = await loadedCardRepository();
  final settings = await loadedSettingsRepository(cards);
  await tester.pumpWidget(MaterialApp(
    home: GameScreen(cardRepository: cards, settingsRepository: settings),
  ));
}

String currentTitle(WidgetTester tester) {
  final title = find.descendant(of: find.byType(AppBar), matching: find.byType(Text)).first;
  return tester.widget<Text>(title).data!;
}

void main() {
  testWidgets('Next shows another card and Back returns to the first', (tester) async {
    await pumpGame(tester);
    final first = currentTitle(tester);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_back)).onPressed, isNull);

    await tester.tap(find.byTooltip('Next card'));
    await tester.pumpAndSettle();
    expect(currentTitle(tester), isNot(first));

    await tester.tap(find.byTooltip('Previous card'));
    await tester.pumpAndSettle();
    expect(currentTitle(tester), first);
  });

  testWidgets('Text button opens a sheet that fits its text and stays on screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await pumpGame(tester);
    final name = currentTitle(tester);

    await tester.tap(find.byTooltip('Card text'));
    await tester.pumpAndSettle();

    expect(find.text(name), findsWidgets);
    expect(find.text('Text for $name'), findsWidgets);
    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(sheet.bottom, lessThanOrEqualTo(800));
    expect(sheet.height, lessThan(400)); // short text: the sheet wraps it instead of filling the screen
  });

  testWidgets('turns the card upright in a wide window and leaves it tall in a narrow one', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tester.view.physicalSize = const Size(400, 800);
    await pumpGame(tester);
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox).first).quarterTurns, 0);

    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox).first).quarterTurns, 1);
  });
}
