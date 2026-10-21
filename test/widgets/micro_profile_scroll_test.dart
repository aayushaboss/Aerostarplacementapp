import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aerostar_edge/screens/onboarding/micro_profile_screen.dart';
import 'package:aerostar_edge/state/app_state.dart';
import 'package:aerostar_edge/theme/app_theme.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, {double height = 420}) async {
    tester.view.physicalSize = Size(720, height * 2); // 360 wide; 420 is short, like a phone with the keyboard open
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(theme: AppTheme.light, home: const MicroProfileScreen()),
    ));
    await tester.pump();
  }

  bool onScreen(WidgetTester tester, Finder f, {double height = 420}) {
    final rect = tester.getRect(f);
    // Above the fixed Continue bar (about 80px tall) and below the progress bar.
    return rect.top >= 60 && rect.bottom <= height - 80;
  }

  testWidgets('picking a city scrolls the "which best describes you" question into view', (tester) async {
    await pumpScreen(tester);
    final heading = find.text('Which best describes you?');
    expect(onScreen(tester, heading), isFalse, reason: 'starts below the fold on a short phone');

    await tester.enterText(find.byType(TextField).last, 'Mumbai');
    await tester.pump();
    await tester.tap(find.text('Mumbai').last);
    await tester.pumpAndSettle();

    expect(onScreen(tester, heading), isTrue);
    // The picked city must stay in the field (it used to be wiped the instant it was chosen).
    expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text, 'Mumbai');
  });

  testWidgets('a typed city stays in the field after pressing done', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField).last, 'Pune');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text, 'Pune');
  });

  testWidgets('choosing Working scrolls the follow-up question and its options into view', (tester) async {
    await pumpScreen(tester, height: 640);
    await tester.ensureVisible(find.text('Working professional'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Working professional'));
    await tester.pumpAndSettle();

    expect(find.text("What's the highest level you've completed?"), findsOneWidget);
    expect(onScreen(tester, find.text("What's the highest level you've completed?"), height: 640), isTrue);
    expect(onScreen(tester, find.text('Graduate'), height: 640), isTrue);
  });
}
