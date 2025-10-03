// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:uvexpress_eticket/main.dart';

void main() {
  testWidgets('UVexpress app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UVExpressApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that our app starts with the home screen.
    expect(find.text('UVexpress'), findsOneWidget);
    expect(find.text('E-Ticket Reservation'), findsOneWidget);
  });
}
