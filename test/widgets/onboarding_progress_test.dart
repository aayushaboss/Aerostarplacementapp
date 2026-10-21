import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerostar_edge/widgets/onboarding_progress.dart';

void main() {
  Future<double> barValue(WidgetTester tester, OnboardingProgress bar) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: bar)));
    await tester.pumpAndSettle();
    return tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!;
  }

  testWidgets('a finished first step of two is only half way, not 100%', (tester) async {
    final v = await barValue(tester, const OnboardingProgress(step: 1, totalSteps: 2, stepFill: 1));
    expect(v, closeTo(0.5, 0.001));
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('the last step reaches 100% only when it is filled in', (tester) async {
    expect(await barValue(tester, const OnboardingProgress(step: 2, totalSteps: 2, stepFill: 0.5)), closeTo(0.75, 0.001));
    expect(await barValue(tester, const OnboardingProgress(step: 2, totalSteps: 2, stepFill: 1)), closeTo(1.0, 0.001));
  });
}
