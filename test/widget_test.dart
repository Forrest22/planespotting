import 'package:flutter_test/flutter_test.dart';

import 'package:planespotting/main.dart';

void main() {
  testWidgets('Menu shows Start, Options and About', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
