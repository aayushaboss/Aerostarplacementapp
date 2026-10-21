import 'config/resume_flow.dart';
import 'models/user.dart';

/// Single source of truth for where a user should land based on onboarding
/// progress. Mirrors frontend/src/nav.ts routeForUser.
///
/// Segment is no longer its own screen/step — it's asked on the profile
/// screen alongside college/class details, so `segment == null` is the
/// signal that the profile screen hasn't been finished yet (name/city can
/// already be set at this point from the mocked Google sign-in, so they
/// can't be used as the "still needs onboarding" check).
String routeForUser(User? user) {
  if (user == null) return '/onboarding';
  if (user.segment == null) return '/onboarding/profile';
  if (!user.onboardingComplete) {
    // School users finish required profile data on the profile screen, then
    // home. College users pick goals/roles next, then home — resume
    // building is no longer part of onboarding at all; it's deferred to
    // whenever the student actually tries to apply (see
    // services/apply_flow.dart's own independent resume gate, which
    // enforces this regardless of onboarding).
    if (user.segment == Segment.school) return '/tabs';
    if (user.goal == null) return '/college/goals';
    return '/tabs';
  }
  return '/tabs';
}

/// Where "build my resume from scratch" goes. Follows [kResumeFlow]: the chat
/// Resume Helper (flow 2) or the guided 7-step quiz (flow 1). Per-section
/// edits (`/college/resume/build?step=N`) always use the quiz.
String resumeBuildLocation({String? applyFor}) {
  final base = kResumeFlow == ResumeFlow.chat ? '/college/resume/chat' : '/college/resume/build';
  return applyFor == null ? base : '$base?applyFor=$applyFor';
}
