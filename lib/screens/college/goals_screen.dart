import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/course_fields.dart';
import '../../mockData/mock_profile_options.dart';
import '../../mockData/related_roles.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/onboarding_progress.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/onboarding_frame.dart';

class _GoalOption {
  final String key;
  final String title;
  const _GoalOption({required this.key, required this.title});
}

// Single words only, on purpose: three equal-width chips leave each label very little room.
const _goals = [
  _GoalOption(key: 'internship', title: 'Internship'),
  _GoalOption(key: 'job', title: 'Full-time'),
  _GoalOption(key: 'both', title: 'Both'),
];

/// Mirrors frontend/app/college/goals.tsx (Goals).
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _goal = '';
  List<String> _selectedRoles = [];
  final _searchController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final user = appState.user;
    // Only default on first-time onboarding — a post-onboarding revisit to
    // edit goals should never silently override a choice the user already
    // made and saved. Previously this screen didn't hydrate _goal/roles
    // from the saved user at all on that path, leaving both blank — which
    // meant tapping Continue/Save without touching anything would silently
    // overwrite a real saved goal/roles with an empty one. Hydrate instead.
    if (user?.onboardingComplete == true) {
      _goal = user?.goal ?? '';
      _selectedRoles = List.of(user?.roles ?? const <String>[]);
      return;
    }
    // Postgrads are more often job-hunting than internship-hunting, and
    // vice versa for undergrads — a reasonable starting point, not a
    // restriction; still a single tap to change either way.
    final segment = user?.segment;
    if (segment == Segment.pg) {
      _goal = 'job';
    } else if (segment == Segment.ug) {
      _goal = 'internship';
    }
    // Pre-select roles matching the course/field they just entered on the
    // previous screen — turns this from a cold "pick from scratch" chip
    // list into "confirm or adjust," using data the flow already
    // collected one screen earlier rather than asking again. Only a
    // starting point (still a single tap each to remove/add), and only
    // for first-time onboarding — same reasoning as the goal default
    // above, a post-onboarding edit should never override a choice
    // someone already made and saved.
    final suggested = rolesByField[courseFieldFor(user?.course)];
    if (suggested != null && suggested.isNotEmpty) {
      _selectedRoles = suggested.take(2).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleRole(String r) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRoles = _selectedRoles.contains(r)
          ? _selectedRoles.where((x) => x != r).toList()
          : [..._selectedRoles, r];
    });
  }

  bool get _valid => _goal.isNotEmpty && _selectedRoles.isNotEmpty;

  bool get _postOnboarding => context.read<AppState>().user?.onboardingComplete == true;

  Future<void> _finish() async {
    if (!_valid) return;
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final wasPostOnboarding = _postOnboarding;
      // TODO: replace with real API call (local mock)
      await appState.updateProfile((current) => current.copyWith(
            goal: _goal,
            roles: _selectedRoles,
            // Goals is now the true last onboarding step — resume-building
            // (and, before that, career preferences) both used to sit
            // between here and Home; both are optional Profile-tab
            // sections now instead of forced onboarding steps. Only set
            // here, not unconditionally, so a post-onboarding edit (Profile
            // → "Goals & roles") can't accidentally re-flip an
            // already-true flag — it's already true by then regardless.
            onboardingComplete: wasPostOnboarding ? null : true,
          ));
      if (!mounted) return;
      if (wasPostOnboarding) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/tabs');
        }
      } else {
        // Goals is the true last onboarding step for this segment — see
        // onboarding_complete_screen.dart for why this doesn't go
        // straight to /tabs any more.
        context.go('/onboarding/complete');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final course = context.watch<AppState>().user?.course;
    final suggestedRoles = rolesByField[courseFieldFor(course)] ?? mockAllRoles;
    final query = _searchController.text.trim().toLowerCase();
    // Each pick pulls in its related roles too, so the list grows with
    // relevant suggestions instead of staying static after the first tap.
    final relatedToSelected = _selectedRoles.expand((r) => relatedRoles[r] ?? const <String>[]);
    // Default view stays scoped to the student's field so it doesn't feel
    // like a generic checklist; searching (or an already-picked role from
    // outside that set) opens it back up to everything.
    final filtered = query.isEmpty
        ? {...suggestedRoles, ..._selectedRoles, ...relatedToSelected}.toList()
        : mockAllRoles.where((r) => r.toLowerCase().contains(query)).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: OnboardingFrame(maxWidth: 640, child: Column(
          children: [
            // During onboarding the back arrow and the progress bar stay fixed at the top, the
            // same header as the profile step. Later edits from the Profile tab have no steps.
            if (!_postOnboarding)
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackChevron(color: AppColors.ink, fallbackRoute: '/onboarding/profile'),
                    const SizedBox(height: AppSpacing.sm),
                    OnboardingProgress(step: 2, totalSteps: 2, stepFill: ((_goal.isNotEmpty ? 1 : 0) + (_selectedRoles.isNotEmpty ? 1 : 0)) / 2),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, _postOnboarding ? topInset + AppSpacing.lg : AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                children: [
                  if (_postOnboarding) const BackChevron(color: AppColors.ink, fallbackRoute: '/tabs'),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Text('What are you looking for?', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                  ),
                  // Three chips on one row: no icons, no sub-labels.
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Row(
                      children: [
                        for (final g in _goals) ...[
                          if (g != _goals.first) const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _goal = g.key);
                              },
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: _goal == g.key ? AppColors.blue : AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(g.title, maxLines: 1, style: AppTextStyles.body.copyWith(color: _goal == g.key ? AppColors.white : AppColors.ink, fontWeight: _goal == g.key ? AppFontWeight.semibold : AppFontWeight.medium)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
                    child: Text('Interested roles', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold)),
                  ),
                  // The search box sits right under the heading so it is always on screen; the
                  // suggestions flow below it (and the keyboard never covers them).
                  PillInput(
                    controller: _searchController,
                    placeholder: 'Search roles…',
                    icon: Ionicons.search_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: filtered
                          .map((r) => AppChip(label: r, selected: _selectedRoles.contains(r), showCheck: true, onPressed: () => _toggleRole(r)))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
              decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
              child: PillButton(label: _postOnboarding ? 'Save' : 'Continue', onPressed: _finish, loading: _loading, disabled: !_valid),
            ),
          ],
        )),
      ),
    );
  }
}
