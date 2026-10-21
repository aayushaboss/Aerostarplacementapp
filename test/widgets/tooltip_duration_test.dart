import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerostar_edge/theme/app_theme.dart';

void main() {
  testWidgets('tap tooltips stay readable for several seconds, then fade away', (tester) async {
    const message = "Puts you in realistic workplace scenarios to see how you'd actually respond.";
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Tooltip(message: message, triggerMode: TooltipTriggerMode.tap, child: Icon(Icons.info_outline)),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump();
    expect(find.text(message), findsOneWidget);

    // The old default (about 1.5s) had already hidden it by now.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text(message), findsOneWidget, reason: 'still readable after 5 seconds');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing, reason: 'fades away after the show duration');
  });
}
