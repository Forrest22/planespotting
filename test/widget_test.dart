import 'package:flutter_test/flutter_test.dart';

import 'package:planespotting/main.dart';

import 'support/test_data.dart';

void main() {
  testWidgets('Menu shows Start, Browse cards, Options and About', (WidgetTester tester) async {
    final cards = await loadedCardRepository();
    final settings = await loadedSettingsRepository(cards);

    await tester.pumpWidget(MyApp(cardRepository: cards, settingsRepository: settings));

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Browse cards'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
