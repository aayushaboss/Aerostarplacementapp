import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/career_dna.dart';
import 'models/parsed_resume.dart';
import 'nav.dart';
import 'screens/dev/style_guide_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/college/career_dna/career_dna_final_report_screen.dart';
import 'screens/college/career_dna/career_dna_landing_screen.dart';
import 'screens/college/career_dna/career_dna_level_intro_screen.dart';
import 'screens/college/career_dna/career_dna_quiz_screen.dart';
import 'screens/college/career_dna/career_dna_report_screen.dart';
import 'screens/college/career_dna/career_dna_success_screen.dart';
import 'screens/college/goals_screen.dart';
import 'screens/college/opportunity_category_picker_screen.dart';
import 'screens/college/opportunity_detail_screen.dart';
import 'screens/college/opportunity_filter_screen.dart';
import 'screens/college/opportunity_list_screen.dart';
import 'screens/college/recently_deleted_applications_screen.dart';
import 'screens/college/resume_builder_quiz_screen.dart';
import 'screens/college/resume_chat_screen.dart';
import 'screens/college/resume_screen.dart';
import 'screens/onboarding/landing_screen.dart';
import 'screens/onboarding/micro_profile_screen.dart';
import 'screens/onboarding/onboarding_complete_screen.dart';
import 'screens/school/aptitude_intro_screen.dart';
import 'screens/school/aptitude_screen.dart';
import 'screens/school/course_category_picker_screen.dart';
import 'screens/school/course_filter_screen.dart';
import 'screens/school/course_search_results_screen.dart';
import 'screens/school/courses_explore_screen.dart';
import 'screens/school/results_screen.dart';
import 'screens/shared/application_detail_screen.dart';
import 'screens/shared/booking_confirmed_screen.dart';
import 'screens/shared/booking_screen.dart';
import 'screens/shared/course_detail_screen.dart';
import 'screens/shared/notifications_screen.dart';
import 'screens/shared/profile_edit_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/shared/recruiter_actions_screen.dart';
import 'screens/shared/saved_screen.dart';
import 'screens/shared/search_appearances_screen.dart';
import 'screens/shared/sessions_screen.dart';
import 'screens/shared/skill_story_screen.dart';
import 'screens/shared/support_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tabs/tabs_scaffold.dart';
import 'snackbar_observer.dart';
import 'state/app_state.dart';
import 'widgets/app_shell.dart';
import 'widgets/placeholder_screen.dart';

/// Auth-entry screens — reachable while signed out, and the destination a
/// signed-in user should be bounced *away* from once fully onboarded.
const _authEntryRoutes = {'/onboarding', '/onboarding/profile', '/auth/login', '/auth/otp'};

/// Single source of truth for app navigation. Replaces the interim
/// Navigator.push + resolveRoute pattern used while screens were converted
/// one at a time (Step 3).
GoRouter buildRouter(AppState appState, GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: appState,
    observers: [SnackBarDismissObserver(scaffoldMessengerKey)],
    redirect: (context, state) {
      // Bootstrap hasn't resolved yet — splash owns navigation until then.
      if (appState.loading) return null;

      final path = state.matchedLocation;
      if (path == '/splash') return null;

      final user = appState.user;
      final isAuthEntry = _authEntryRoutes.contains(path);

      // Fully onboarded users shouldn't land back on the sign-in screens —
      // e.g. a bookmark, shared link, or browser back button pointed at '/'.
      if (user != null && user.onboardingComplete && isAuthEntry) {
        return '/tabs';
      }

      // Anything else requires a signed-in user — a signed-out visitor
      // pasting a deep link (e.g. /tabs, /college/goals) gets sent to the
      // start of onboarding instead of rendering a screen with no user.
      //
      // Two of the routes in _authEntryRoutes need real context beyond
      // "no user yet" to be safely reachable, even though they're exempt
      // from the check above: /onboarding/profile expects a sign-in
      // that's already in progress (a signed-out deep link here used to
      // silently fabricate a throwaway 'guest' account via
      // AppState.updateProfile instead of rendering nothing), and
      // /auth/otp expects an actual pending OTP request (a signed-out
      // deep link here — with no identifier — used to accept a resend
      // after the 30s countdown and verify against the fixed demo code
      // with nothing ever having been sent). Both stay reachable for a
      // signed-out visitor arriving the normal way (pushed from Landing/
      // Login), since that push always carries the identifier/segment
      // context this redirect can't see — this only catches a bare,
      // out-of-sequence deep link.
      //
      // BUG FIX: this used to redirect on `path == '/auth/otp'` alone,
      // with no check of the identifier query param the comment above
      // actually describes — every signed-out visit to /auth/otp,
      // including the legitimate one right after "Send OTP", was bounced
      // straight back to onboarding. Login is impossible without this
      // check actually reading the identifier that's present.
      final otpIdentifier = state.uri.queryParameters['identifier']?.trim();
      final needsInProgressContext =
          path == '/onboarding/profile' || (path == '/auth/otp' && (otpIdentifier == null || otpIdentifier.isEmpty));
      if (user == null && (!isAuthEntry || needsInProgressContext)) {
        return '/onboarding';
      }

      // For a signed-in user on anything other than the auth-entry chain,
      // make sure they're actually on (or heading to) their correct
      // in-progress onboarding step — without this, any protected route
      // (/tabs, /college/resume, /profile-edit, a booking sheet, ...) was
      // directly reachable via a deep link or a stale tab while mid-
      // onboarding, rendering against a User object missing whatever
      // segment/goal/etc. that route assumes already exists. Only
      // enforced while genuinely incomplete — once routeForUser resolves
      // to '/tabs', a fully (or segment-appropriately) onboarded user is
      // free to be anywhere in the app, not pinned to exactly '/tabs'.
      if (user != null && !isAuthEntry) {
        final expected = routeForUser(user);
        if (expected != '/tabs' && expected != path) return expected;
      }

      // Career Quiz deep-link guard: levels unlock sequentially, so
      // pasting /college/career-dna/level/5/quiz with L1-4 unfinished
      // otherwise loads real L5 questions and — on submit — persists a
      // garbage result and marks L5 "complete" while the earlier levels
      // aren't. Also bounces an out-of-range level number (the screens'
      // own `firstWhere` on the meta list would throw a StateError).
      final careerLevel = RegExp(r'^/college/career-dna/level/(\d+)/(intro|quiz|complete)$').firstMatch(path);
      if (careerLevel != null) {
        final level = int.tryParse(careerLevel.group(1)!);
        final action = careerLevel.group(2);
        if (user == null || level == null || level < 1 || level > 5) return '/tabs/career-dna';
        if ((action == 'intro' || action == 'quiz') && !user.isCareerDnaLevelUnlocked(level)) {
          return '/tabs/career-dna';
        }
        if (action == 'complete' && !user.careerDnaOrEmpty.isLevelComplete(level)) {
          return '/tabs/career-dna';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/onboarding/profile', builder: (context, state) => const MicroProfileScreen()),
      GoRoute(path: '/onboarding/complete', builder: (context, state) => const OnboardingCompleteScreen()),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => LoginScreen(
          returning: state.uri.queryParameters['returning'] == '1',
          startOnEmail: state.uri.queryParameters['mode'] == 'email',
        ),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => OtpScreen(
          identifier: state.uri.queryParameters['identifier'] ?? '',
          returning: state.uri.queryParameters['returning'] == '1',
        ),
      ),
      GoRoute(path: '/school/aptitude-intro', builder: (context, state) => const AptitudeIntroScreen()),
      GoRoute(path: '/school/aptitude', builder: (context, state) => const AptitudeScreen()),
      GoRoute(
        path: '/college/resume/build',
        // Keyed on the step param so navigating between steps (e.g. from
        // "Add to profile") always mounts a fresh screen instead of
        // silently no-op'ing when the widget is already on-screen.
        builder: (context, state) => ResumeBuilderQuizScreen(
          key: ValueKey('resume-build-${state.uri.queryParameters['step'] ?? '0'}'),
          applyForOpportunityId: state.uri.queryParameters['applyFor'],
          initialStep: int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 0,
        ),
      ),
      // Resume flow 2 (chat). Flow 1 is /college/resume/build above; which one the
      // app opens is decided by kResumeFlow via resumeBuildLocation().
      GoRoute(
        path: '/college/resume/chat',
        builder: (context, state) => ResumeChatScreen(
          key: ValueKey('resume-chat-${state.uri.queryParameters['applyFor'] ?? ''}'),
          applyForOpportunityId: state.uri.queryParameters['applyFor'],
          uploaded: state.extra is ParsedResume ? state.extra as ParsedResume : null,
        ),
      ),
      GoRoute(path: '/college/goals', builder: (context, state) => const GoalsScreen()),
      GoRoute(
        path: '/college/career-dna/level/:level/intro',
        builder: (context, state) => CareerDnaLevelIntroScreen(level: int.parse(state.pathParameters['level']!)),
      ),
      GoRoute(
        path: '/college/career-dna/level/:level/quiz',
        builder: (context, state) => CareerDnaQuizScreen(level: int.parse(state.pathParameters['level']!)),
      ),
      GoRoute(
        path: '/college/career-dna/level/:level/complete',
        builder: (context, state) => CareerDnaSuccessScreen(level: int.parse(state.pathParameters['level']!)),
      ),
      // Dev-only living style guide (Round V) — gated behind kDebugMode so
      // this route (and StyleGuideScreen itself, once tree-shaken) is
      // entirely absent from a release build. No nav-bar link anywhere;
      // reachable only by typing the URL in a local debug build.
      if (kDebugMode) GoRoute(path: '/dev/style-guide', builder: (context, state) => const StyleGuideScreen()),
      // Every other pushed page keeps the navigation (rail or sidebar) visible on a wide window; on
      // a phone the shell is a pass-through, so these still cover the whole screen.
      ShellRoute(
        builder: (context, state, child) => PushedShell(state: state, child: child),
        routes: [
        GoRoute(path: '/school/results', builder: (context, state) => ResultsScreen(initialCluster: state.uri.queryParameters['cluster'])),
        GoRoute(
          path: '/school/course-filter',
          builder: (context, state) => CourseFilterScreen(initial: state.extra as CourseFilterSelection? ?? const CourseFilterSelection()),
        ),
        GoRoute(
          path: '/school/course-category-picker',
          builder: (context, state) => CourseCategoryPickerScreen(initialSelected: (state.extra as List<String>?) ?? const []),
        ),
        GoRoute(
          path: '/college/resume',
          builder: (context, state) => ResumeScreen(applyForOpportunityId: state.uri.queryParameters['applyFor']),
        ),
        GoRoute(
          path: '/college/career-dna/level/:level/report',
          builder: (context, state) => CareerDnaReportScreen(level: int.parse(state.pathParameters['level']!)),
        ),
        GoRoute(path: '/college/career-dna/final-report', builder: (context, state) => const CareerDnaFinalReportScreen()),
        GoRoute(
          path: '/booking',
          builder: (context, state) => BookingScreen(
            kind: state.uri.queryParameters['kind'] ?? 'counseling',
            bookingId: state.uri.queryParameters['bookingId'],
            initialDate: state.uri.queryParameters['date'],
            initialTime: state.uri.queryParameters['time'],
            initialMode: state.uri.queryParameters['mode'],
            initialSessionType: state.uri.queryParameters['sessionType'],
          ),
        ),
        GoRoute(
          path: '/booking-confirmed',
          builder: (context, state) => BookingConfirmedScreen(
            kind: state.uri.queryParameters['kind'] ?? 'counseling',
            date: state.uri.queryParameters['date'] ?? '',
            time: state.uri.queryParameters['time'] ?? '',
            mode: state.uri.queryParameters['mode'] ?? 'online',
            counselor: state.uri.queryParameters['counselor'] ?? '',
            sessionType: state.uri.queryParameters['sessionType'] ?? '',
            venueName: state.uri.queryParameters['venueName'] ?? '',
            venueAddress: state.uri.queryParameters['venueAddress'] ?? '',
          ),
        ),
        GoRoute(path: '/opportunity/:id', builder: (context, state) => OpportunityDetailScreen(id: state.pathParameters['id']!)),
        GoRoute(
          path: '/opportunities',
          builder: (context, state) {
            final q = state.uri.queryParameters['q'];
            return OpportunityListScreen(
              title: state.uri.queryParameters['title'] ?? (q != null && q.isNotEmpty ? '"$q"' : 'Opportunities'),
              category: state.uri.queryParameters['category'],
              ids: state.uri.queryParameters['ids']?.split(','),
              query: q,
            );
          },
        ),
        GoRoute(
          path: '/courses/search',
          builder: (context, state) => CourseSearchResultsScreen(
            query: state.uri.queryParameters['q'] ?? '',
            category: state.uri.queryParameters['category'],
          ),
        ),
        GoRoute(path: '/application/:id', builder: (context, state) => ApplicationDetailScreen(id: state.pathParameters['id']!)),
        GoRoute(path: '/applications/recently-deleted', builder: (context, state) => const RecentlyDeletedApplicationsScreen()),
        GoRoute(path: '/course/:id', builder: (context, state) => CourseDetailScreen(id: state.pathParameters['id']!)),
        GoRoute(
          path: '/profile-edit',
          builder: (context, state) => ProfileEditScreen(
            returnTo: state.uri.queryParameters['returnTo'],
            scrollToSection: state.uri.queryParameters['section'],
          ),
        ),
        GoRoute(path: '/college/opportunity-filter', builder: (context, state) => const OpportunityFilterScreen()),
        GoRoute(
          path: '/college/opportunity-category-picker',
          builder: (context, state) => OpportunityCategoryPickerScreen(initialSelected: (state.extra as List<String>?) ?? const []),
        ),
        GoRoute(path: '/search-appearances', builder: (context, state) => const SearchAppearancesScreen()),
        GoRoute(path: '/recruiter-actions', builder: (context, state) => const RecruiterActionsScreen()),
        GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
        GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
        // Re-enabled — the app otherwise had zero Help/Support entry point
        // anywhere in either segment's 4 main-nav screens (a real Heuristic-10
        // "help and documentation" gap), and this screen's FAQ/contact
        // content, while built from a naukri/internshala reference, is real
        // and functional, not placeholder — better to ship it than leave
        // users with no path to help at all.
        GoRoute(path: '/support', builder: (context, state) => const SupportScreen()),
        GoRoute(path: '/story/:id', builder: (context, state) => SkillStoryScreen(id: state.pathParameters['id']!)),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TabsScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/tabs', builder: (context, state) => const HomeTabScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/browse', builder: (context, state) => const BrowseTabScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/sessions', builder: (context, state) => const SessionsScreen())]),
          // College-only branch (hidden from the tab bar for school users,
          // see TabsScaffold) — course discovery, replacing what used to be
          // a dedicated "Saved" tab. Saved opportunities are still reachable,
          // just demoted to a Profile row instead of a primary tab slot.
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/explore', builder: (context, state) => const CoursesExploreScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/profile', builder: (context, state) => const ProfileScreen())]),
          // College-only, hidden from school's tab bar (see TabsScaffold) —
          // appended at the end (index 5) rather than reordered in, so
          // every existing branch's index stays exactly what it was.
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/career-dna', builder: (context, state) => const CareerDnaLandingScreen())]),
        ],
      ),
    ],
    errorBuilder: (context, state) => PlaceholderScreen(routeName: state.uri.toString()),
  );
}
