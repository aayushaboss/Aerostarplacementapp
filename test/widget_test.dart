import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerostar_edge/main.dart';
import 'package:aerostar_edge/widgets/brand.dart';

void main() {
  testWidgets('App boots and renders the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AerostarEdgeApp());
    await tester.pump();

    expect(find.byKey(const ValueKey('splash-screen')), findsOneWidget);
    expect(find.byType(Wordmark), findsOneWidget);

    // Flush the splash screen's pending delayed-navigation timers so the
    // test doesn't end with timers still scheduled.
    await tester.pump(const Duration(milliseconds: 2000));
  });
}
