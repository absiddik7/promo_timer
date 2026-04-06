// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:promo_timer/main.dart';

void main() {
  testWidgets('shows candle home with menu access', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    final IconButton menuButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.menu_rounded),
    );
    menuButton.onPressed?.call();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Background color', skipOffstage: false), findsOneWidget);
  });
}
