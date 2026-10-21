import 'user.dart';

/// Post-onboarding profile checklist item for college apply readiness.
class ProfileChecklistItem {
  final String id;
  final String title;
  final String subtitle;
  final bool requiredForApply;
  final bool done;
  final String route;

  const ProfileChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.requiredForApply,
    required this.done,
    required this.route,
  });
}

/// Pure readiness helpers for college profile completion + apply gate.
extension ProfileReadiness on User {
  /// Segment-aware, deliberately mirroring micro_profile_screen.dart's own
  /// `_canContinue` — a single blanket "name/city/college/course/semester
  /// all required" check used to be unsatisfiable for whole segments, since
  /// onboarding never even asks some of those fields depending on segment
  /// (or, for Working, qualification): School asks currentClass+board
  /// instead of college/course/semester entirely; Working only asks
  /// college/course when the qualification is Diploma/Graduate/Postgraduate,
  /// and never asks semester at all; PG asks college/course but not
  /// semester (only UG asks all three). Without this, e.g. a School user or
  /// a Working user with a sub-Diploma qualification could never show as
  /// "done" no matter what they filled in.
  bool get hasBasicInfo {
    final n = name?.trim() ?? '';
    final c = city?.trim() ?? '';
    if (n.isEmpty || c.isEmpty || segment == null) return false;
    switch (segment!) {
      case Segment.school:
        return (currentClass?.trim().isNotEmpty ?? false) && (board?.trim().isNotEmpty ?? false);
      case Segment.working:
        final q = highestQualification?.trim() ?? '';
        if (q.isEmpty) return false;
        // Mirrors micro_profile_screen.dart's _educatedQualifications —
        // keep both in sync if that set ever changes.
        final educated = {'Diploma', 'Graduate', 'Postgraduate'}.contains(q);
        return !educated || ((college?.trim().isNotEmpty ?? false) && (course?.trim().isNotEmpty ?? false));
      case Segment.ug:
      case Segment.pg:
        final hasCollegeCourse = (college?.trim().isNotEmpty ?? false) && (course?.trim().isNotEmpty ?? false);
        final semesterOk = segment == Segment.pg || (semester?.trim().isNotEmpty ?? false);
        return hasCollegeCourse && semesterOk;
    }
  }

  bool get hasResume {
    final r = resume;
    if (r == null) return false;
    // A half-built resume autosaved by the guided builder is not a resume yet.
    if (r.isDraft) return false;
    // Deliberately not `r.name.isNotEmpty` on its own — the quiz's own
    // autosave (resume_builder_quiz_screen.dart's _saveDraft) always sets
    // `name` from the profile the instant *any* optional field is touched
    // (e.g. just typing a headline on step 1), which used to be enough to
    // flip this true — and therefore satisfy the apply-flow gate — without
    // the user ever having filled in an actual section of the resume.
    return r.skills.isNotEmpty || r.education.isNotEmpty || r.projects.isNotEmpty || r.workExperience.isNotEmpty || r.certifications.isNotEmpty;
  }

  bool get hasPhoto => (photoUrl?.trim() ?? '').isNotEmpty;

  bool get hasGoals {
    final g = goal?.trim() ?? '';
    final r = roles;
    return g.isNotEmpty && r != null && r.isNotEmpty;
  }

  bool get hasVideoIntro => (videoIntroUrl?.trim() ?? '').isNotEmpty;

  bool get hasPreferences => !(preferences?.isEmpty ?? true);

  /// Hard unlock for job applications. Basic info used to gate this too,
  /// but it required 5 fields (name/city/college/course/year) with no
  /// visual indication on the edit screen of which were still missing —
  /// a user could look fully filled-in and still be stuck. Resume is the
  /// one thing that actually needs to exist before applying.
  bool get canApply => hasResume;

  /// Every item here that isn't `basic`/`resume` is `requiredForApply: false`
  /// — [missingForApply]/[applyStepsRemaining] filter on that flag, so
  /// growing this list to cover the full Profile tab (not just the apply
  /// gate's 2 required fields) can never change what the apply gate itself
  /// requires. School users only ever see `basic` — the other 3 sections
  /// don't exist on their Profile tab (see profile_screen.dart's `isSchool`
  /// gates), so scoring them against a checklist they have no UI to
  /// complete would strand their percent below 100 forever.
  ///
  /// Exactly 4 items for non-school: Basic info, Resume, Profile photo,
  /// Video profile — the 4 things this app actually asks a college/UG/PG/
  /// Working user to provide. `goals`/`preferences` used to also count here
  /// (a 5th and 6th item) but goals is really part of Basic details (shown
  /// inline on that same card) and preferences moved entirely off the
  /// Profile tab onto college Home's filter icon — neither has its own
  /// dedicated completion story worth surfacing in this percentage anymore.
  List<ProfileChecklistItem> get profileChecklist {
    final basic = ProfileChecklistItem(
      id: 'basic',
      title: 'Basic info',
      subtitle: 'Name, city, college, course, year',
      requiredForApply: false,
      done: hasBasicInfo,
      route: '/profile-edit',
    );
    if (segment == Segment.school) return [basic];

    return [
      basic,
      ProfileChecklistItem(
        id: 'resume',
        title: 'Resume',
        subtitle: 'Paste or build your resume',
        requiredForApply: true,
        done: hasResume,
        route: '/college/resume',
      ),
      ProfileChecklistItem(
        id: 'photo',
        title: 'Profile photo',
        subtitle: 'Add a photo so recruiters recognize you',
        requiredForApply: false,
        done: hasPhoto,
        route: '/profile-edit',
      ),
      ProfileChecklistItem(
        id: 'video',
        title: 'Video profile',
        subtitle: 'A short video pitch',
        requiredForApply: false,
        done: hasVideoIntro,
        // No pushable route — showVideoProfileSheet() opens a modal from a
        // BuildContext, not a GoRoute. Landing on the tab and letting the
        // user tap the visible row is a fine outcome for a checklist item,
        // simpler than teaching every consumer of .route a modal-vs-push
        // special case for this one item.
        route: '/tabs/profile',
      ),
    ];
  }

  int get profileCompletedCount => profileChecklist.where((i) => i.done).length;

  int get profileTotalCount => profileChecklist.length;

  int get profileProgressPercent {
    if (profileTotalCount == 0) return 0;
    return ((profileCompletedCount / profileTotalCount) * 100).round();
  }

  int get applyStepsRemaining =>
      profileChecklist.where((i) => i.requiredForApply && !i.done).length;

  List<ProfileChecklistItem> get missingForApply =>
      profileChecklist.where((i) => i.requiredForApply && !i.done).toList();
}
