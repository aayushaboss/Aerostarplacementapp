import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerostar_edge/data/repositories.dart';
import 'package:aerostar_edge/screens/onboarding/micro_profile_screen.dart';
import 'package:aerostar_edge/state/app_state.dart';
import 'package:aerostar_edge/theme/app_theme.dart';

void main() {
  Future<void> pumpGoogleUser(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final repos = buildRepositories();
    final app = AppState(authRepository: repos.auth);
    await tester.runAsync(() async {
      await app.bootstrap();
      await app.mockGoogleSignIn();
    });
    await tester.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider.value(value: app), Provider<Repositories>.value(value: repos)],
      child: MaterialApp(theme: AppTheme.light, home: const MicroProfileScreen()),
    ));
    await tester.pump();
  }

  // The phone field is the second TextField (the first is the name, the third the city).
  Finder phoneField() => find.byType(TextField).at(2);

  testWidgets('a number cannot be typed past 15 digits', (tester) async {
    await pumpGoogleUser(tester);
    await tester.enterText(phoneField(), '1' * 25);
    await tester.pump();
    expect(tester.widget<TextField>(phoneField()).controller!.text.length, 15);
  });

  testWidgets('a too-short number shows an error, a 10-digit number clears it', (tester) async {
    await pumpGoogleUser(tester);
    await tester.enterText(phoneField(), '12345');
    await tester.pump();
    expect(find.text('Enter a valid phone number (10 digits)'), findsOneWidget);
    await tester.enterText(phoneField(), '9876543210');
    await tester.pump();
    expect(find.text('Enter a valid phone number (10 digits)'), findsNothing);
  });

  testWidgets('while Continue is off, a line says what is still missing', (tester) async {
    await pumpGoogleUser(tester);
    // Google fills the name; the city is the first thing missing.
    expect(find.text('Add your city to continue'), findsOneWidget);
  });
}
