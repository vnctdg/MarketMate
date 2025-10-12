// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:marketmate/main.dart';

void main() {
  testWidgets('MarketMate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MarketMateApp());

    // Wait for the splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that the app loads and shows the grocery page
    expect(find.text('Your Grocery List'), findsOneWidget);
  });
}
