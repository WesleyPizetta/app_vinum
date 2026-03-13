import 'package:flutter_test/flutter_test.dart';

import 'package:vinum/vinum_app.dart';

void main() {
  testWidgets('VinumApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const VinumApp());
    await tester.pumpAndSettle();
    expect(find.text('Vinum'), findsWidgets);
  });
}

