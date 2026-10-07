import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/planar_die.dart';
import 'package:planespotting/ui/core/card_image.dart';
import 'package:planespotting/ui/features/game/views/game_screen.dart';
import 'package:planespotting/ui/features/game/views/planar_die_button.dart';

import '../support/test_data.dart';

/// Always picks the first option, so every die roll is a planeswalk.
class _AlwaysFirst implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;
}

Future<SettingsRepository> pumpGame(WidgetTester tester, {Random? random}) async {
  final cards = await loadedCardRepository();
  final settings = await loadedSettingsRepository(cards);
  await tester.pumpWidget(MaterialApp(
    home: GameScreen(cardRepository: cards, settingsRepository: settings, random: random),
  ));
  return settings;
}

/// The game opens with no card; the start button reveals the first one.
Future<void> startGame(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Planeswalk'));
  await tester.pumpAndSettle();
}

String currentTitle(WidgetTester tester) {
  final title = find.descendant(of: find.byType(AppBar), matching: find.byType(Text)).first;
  return tester.widget<Text>(title).data!;
}

void main() {
  testWidgets('opens with no card and a planeswalk die, and the first roll reveals a card', (tester) async {
    await pumpGame(tester);
    expect(find.text('Planeswalk to begin'), findsOneWidget);
    expect(find.byType(CardImage), findsNothing);
    final dieFace = find.descendant(of: find.byType(FloatingActionButton), matching: find.byType(PlanarDieGlyph));
    expect(tester.widget<PlanarDieGlyph>(dieFace).face, DieFace.planeswalk);

    await tester.tap(find.byTooltip('Roll die'));
    await tester.pump(); // the spin's clock starts on its first frame
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Planeswalk to begin'), findsNothing);
    expect(find.byType(CardImage), findsWidgets);
    expect(find.text('Nothing happens'), findsNothing); // the opening roll isn't a random result
    expect(tester.widget<PlanarDieGlyph>(dieFace).face, isNull);
    // The resting die shows a naught, not an empty button.
    expect(
      find.descendant(of: find.byType(FloatingActionButton), matching: find.bySemanticsLabel('Blank')),
      findsOneWidget,
    );
  });

  testWidgets('Next shows another card and Back returns to the first', (tester) async {
    await pumpGame(tester);
    await startGame(tester);
    final first = currentTitle(tester);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_back)).onPressed, isNull);

    await tester.tap(find.byTooltip('Next card'));
    await tester.pumpAndSettle();
    expect(currentTitle(tester), isNot(first));

    await tester.tap(find.byTooltip('Previous card'));
    await tester.pumpAndSettle();
    expect(currentTitle(tester), first);
  });

  testWidgets('Card text toggles a sheet attached to the bottom bar that stays on across cards', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await pumpGame(tester);
    await startGame(tester);
    final panel = find.byKey(const ValueKey('card-text-panel'));
    final name = currentTitle(tester);
    expect(panel, findsNothing);

    await tester.tap(find.byTooltip('Show card text'));
    await tester.pumpAndSettle();
    expect(panel, findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text(name)), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('Text for $name')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('Illustrated by Artist of $name')), findsOneWidget);
    // It grows out of the bottom bar: flush on top of it, and never taller than 60% of the body.
    final rect = tester.getRect(panel);
    expect(rect.bottom, tester.getRect(find.byType(BottomAppBar)).top);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(400));
    expect(rect.height, lessThan(800 * 0.6));

    await tester.tap(find.byTooltip('Next card'));
    await tester.pumpAndSettle();
    final next = currentTitle(tester);
    expect(next, isNot(name));
    expect(find.descendant(of: panel, matching: find.text('Text for $next')), findsOneWidget);

    await tester.tap(find.byTooltip('Hide card text'));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
  });

  testWidgets('turns the card upright in a wide window and leaves it tall in a narrow one', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tester.view.physicalSize = const Size(400, 800);
    await pumpGame(tester);
    await startGame(tester);
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox).first).quarterTurns, 0);

    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox).first).quarterTurns, 1);
  });

  testWidgets('rolling flashes through several faces, then shows the result banner', (tester) async {
    await pumpGame(tester);
    await startGame(tester);
    expect(find.text('Roll die'), findsOneWidget);
    final dieFace = find.descendant(of: find.byType(FloatingActionButton), matching: find.byType(PlanarDieGlyph));

    await tester.tap(find.byTooltip('Roll die'));
    await tester.pump(); // the animation's clock starts on its first frame
    final seen = <DieFace?>{};
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      seen.addAll(tester.widgetList<PlanarDieGlyph>(dieFace).map((glyph) => glyph.face));
    }
    expect(seen.length, greaterThan(1)); // it cycled; it didn't just sit on one face
    await tester.pump(const Duration(milliseconds: 500)); // banner pops in
    final results = ['Planeswalk!', 'Chaos!', 'Nothing happens'];
    expect(results.where((word) => find.text(word).evaluate().isNotEmpty), hasLength(1));

    await tester.pump(const Duration(seconds: 4)); // lets a blank banner's timer finish
    await tester.pumpAndSettle();
  });

  testWidgets('a planeswalk roll moves to the next plane by itself, unless the option is off', (tester) async {
    final settings = await pumpGame(tester, random: _AlwaysFirst());
    await startGame(tester);

    Future<void> rollAndWaitForBanner() async {
      await tester.tap(find.byTooltip('Roll die'));
      await tester.pump(); // the animation's clock starts on its first frame
      await tester.pump(const Duration(milliseconds: 1250));
      await tester.pump(const Duration(milliseconds: 500)); // banner pops in
      expect(find.text('Planeswalk!'), findsOneWidget);
    }

    var before = currentTitle(tester);
    await rollAndWaitForBanner();
    expect(currentTitle(tester), before); // the banner shows first
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(currentTitle(tester), isNot(before));

    await settings.setAutoPlaneswalk(false);
    before = currentTitle(tester);
    await rollAndWaitForBanner();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(currentTitle(tester), before);
  });
}
