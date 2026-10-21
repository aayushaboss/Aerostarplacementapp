import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerostar_edge/data/repositories.dart';
import 'package:aerostar_edge/mockData/mock_opportunities.dart';
import 'package:aerostar_edge/mockData/mock_courses.dart';
import 'package:aerostar_edge/models/user.dart';
import 'package:aerostar_edge/router.dart';
import 'package:aerostar_edge/state/app_state.dart';
import 'package:aerostar_edge/theme/app_theme.dart';

import '../helpers/load_catalog.dart';

/// Opens every route of the real app, signed in as the right kind of user, at tablet sizes
/// and fails on any layout overflow or build error, at phone, tablet and desktop sizes. Catches a
/// screen that only works at one width.

enum Who { signedOut, newUser, midOnboarding, justDone, college, school }

const _sizes = <String, Size>{
  'phone-small': Size(360, 740),
  'phone': Size(390, 844),
  'medium-min': Size(600, 960),
  'tablet-portrait': Size(768, 1024),
  'tablet-landscape': Size(1024, 768),
  'desktop': Size(1280, 800),
  'desktop-wide': Size(1440, 900),
};

List<(Who, String)> _routes() {
  final job = mockOpportunities.first.id;
  final course = mockCourses.first.id;
  return [
    (Who.signedOut, '/onboarding'),
    (Who.signedOut, '/auth/login'),
    (Who.signedOut, '/auth/login?mode=email'),
    (Who.signedOut, '/auth/login?returning=1'),
    (Who.signedOut, '/auth/otp?identifier=9876543210'),
    (Who.newUser, '/onboarding/profile'),
    (Who.midOnboarding, '/college/goals'),
    (Who.justDone, '/onboarding/complete'),
    (Who.college, '/tabs'),
    (Who.college, '/tabs/browse'),
    (Who.college, '/tabs/sessions'),
    (Who.college, '/tabs/explore'),
    (Who.college, '/tabs/profile'),
    (Who.college, '/tabs/career-dna'),
    (Who.college, '/college/resume'),
    (Who.college, '/college/resume/build'),
    (Who.college, '/college/resume/chat'),
    (Who.college, '/college/career-dna/level/1/intro'),
    (Who.college, '/college/career-dna/level/1/quiz'),
    (Who.college, '/college/career-dna/level/1/complete'),
    (Who.college, '/college/career-dna/level/1/report'),
    (Who.college, '/college/career-dna/final-report'),
    (Who.college, '/booking'),
    (Who.college, '/booking-confirmed?date=2026-10-20&time=10:00&counselor=Asha'),
    (Who.college, '/opportunity/$job'),
    (Who.college, '/opportunities'),
    (Who.college, '/courses/search?q=marketing'),
    (Who.college, '/application/app-seed-interview'),
    (Who.college, '/applications/recently-deleted'),
    (Who.college, '/course/$course'),
    (Who.college, '/profile-edit'),
    (Who.college, '/college/opportunity-filter'),
    (Who.college, '/college/opportunity-category-picker'),
    (Who.college, '/search-appearances'),
    (Who.college, '/recruiter-actions'),
    (Who.college, '/notifications'),
    (Who.college, '/saved'),
    (Who.college, '/support'),
    (Who.college, '/story/interview-basics'),
    (Who.school, '/tabs'),
    (Who.school, '/tabs/browse'),
    (Who.school, '/tabs/sessions'),
    (Who.school, '/tabs/profile'),
    (Who.school, '/school/aptitude-intro'),
    (Who.school, '/school/aptitude'),
    (Who.school, '/school/results'),
    (Who.school, '/school/course-filter'),
    (Who.school, '/school/course-category-picker'),
  ];
}

Future<void> _loadFonts(WidgetTester tester) async {
  final loader = FontLoader('Poppins');
  for (final f in ['400Regular', '500Medium', '600SemiBold', '700Bold', '800ExtraBold', '900Black']) {
    loader.addFont(rootBundle.load('assets/fonts/Poppins_$f.ttf'));
  }
  final icons = FontLoader('packages/flutter_vector_icons/Ionicons')..addFont(rootBundle.load('packages/flutter_vector_icons/fonts/Ionicons.ttf'));
  await tester.runAsync(() async {
    await loader.load();
    await icons.load();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  loadCatalogFromDisk();

  final routes = _routes();

  for (final sizeEntry in _sizes.entries) {
    for (final (who, route) in routes) {
      testWidgets('${sizeEntry.key} $route ($who)', (tester) async {
        SharedPreferences.setMockInitialValues({});
        await _loadFonts(tester);
        tester.view.physicalSize = sizeEntry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final errors = <String>[];
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
        addTearDown(() => FlutterError.onError = oldHandler);

        final repos = buildRepositories();
        final appState = AppState(authRepository: repos.auth);
        await tester.runAsync(() async {
          await appState.bootstrap();
          if (who != Who.signedOut) {
            await appState.mockGoogleSignIn();
            if (who == Who.college || who == Who.justDone) {
              await appState.updateProfile((u) => u.copyWith(
                    segment: Segment.ug,
                    city: 'Mumbai',
                    college: 'Mumbai University',
                    course: 'B.Com',
                    semester: '4',
                    goal: 'internship',
                    roles: ['Marketing', 'Graphic Designing'],
                    onboardingComplete: true,
                    aptitudeSkipped: true,
                  ));
            } else if (who == Who.school) {
              await appState.updateProfile((u) => u.copyWith(
                    segment: Segment.school,
                    city: 'Pune',
                    currentClass: 'Class 12',
                    onboardingComplete: true,
                  ));
            } else if (who == Who.midOnboarding) {
              await appState.updateProfile((u) => u.copyWith(segment: Segment.ug, city: 'Mumbai', name: 'Aayusha Pagare'));
            }
            if (who == Who.justDone) appState.markJustOnboarded();
          }
        });

        final messengerKey = GlobalKey<ScaffoldMessengerState>();
        final router = buildRouter(appState, messengerKey);
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appState),
            Provider<Repositories>.value(value: repos),
          ],
          child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              scaffoldMessengerKey: messengerKey,
              routerConfig: router,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
        ));
        // The splash screen navigates on its own after about 2 seconds; let it finish first.
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        router.go(route);
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }

        final landed = router.routeInformationProvider.value.uri.toString();
        final notes = <String>[];
        // Level 1's "complete" page redirects back to the level list until the level is done.
        if (landed.split('?').first != route.split('?').first && !route.contains('/level/1/complete')) notes.add('redirected to $landed');
        // Dispose everything and let pending timers drain.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 5));

        expect(errors, isEmpty, reason: '${sizeEntry.key} $route: ${errors.take(3).join(' ; ')}');
        // The sign-in redirects aside, the screen asked for is the screen shown.
        expect(notes, isEmpty, reason: '$route ${notes.join()}');
      });
    }
  }
}
