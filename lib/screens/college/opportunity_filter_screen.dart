import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/job_preferences.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/opportunity_filter_fields.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// Mobile host for the filter fields (see opportunity_filter_fields.dart) —
/// a full-screen push reached from college Home's filter icon, buffered
/// state committed only on Apply. Unlike the Courses tab's filter (purely
/// ephemeral tab-local state), this one hydrates from and saves straight to
/// `AppState.user` on open/apply, since preferences here are meant to be
/// remembered, not reset every visit. Category and Job/Internship bind
/// directly to `User.roles`/`User.goal` (not a separate filter-only copy)
/// — the exact same lists Home's own carousels and match-scoring already
/// read, so the filter can never disagree with the rest of the app about
/// what a user is interested in.
///
/// At desktop widths, `college_feed_screen.dart` renders these same fields
/// itself as a persistent, live-committing panel instead of pushing this
/// screen — this screen's own rendering moved into `OpportunityFilterFields`
/// for that reuse, but its buffered state/Apply/Reset behavior is unchanged.
class OpportunityFilterScreen extends StatefulWidget {
  const OpportunityFilterScreen({super.key});

  @override
  State<OpportunityFilterScreen> createState() => _OpportunityFilterScreenState();
}

class _OpportunityFilterScreenState extends State<OpportunityFilterScreen> {
  List<String> _roles = [];
  String _goal = '';
  String? _workMode;
  String? _employmentType;
  List<String> _cities = [];
  bool _loading = false;

  void _hydrate() {
    final user = context.read<AppState>().user;
    _roles = List.of(user?.roles ?? const []);
    _goal = user?.goal ?? '';
    _workMode = user?.preferences?.workMode;
    _employmentType = user?.preferences?.employmentType;
    _cities = List.of(user?.preferences?.cities ?? const []);
  }

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _pickRoles() async {
    final result = await context.push<List<String>>('/college/opportunity-category-picker', extra: _roles);
    if (result != null) setState(() => _roles = result);
  }

  void _selectGoal(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      _goal = key;
      // Employment type only means anything for Full-time/Both — clear it
      // rather than leave a stale selection that would silently zero out
      // results once Internship is combined with it.
      if (key == 'internship') _employmentType = null;
    });
  }

  void _toggleWorkMode(String mode) {
    HapticFeedback.selectionClick();
    setState(() => _workMode = _workMode == mode ? null : mode);
  }

  void _toggleEmploymentType(String type) {
    if (_goal == 'internship') return;
    HapticFeedback.selectionClick();
    setState(() => _employmentType = _employmentType == type ? null : type);
  }

  void _addCity(String c) {
    final trimmed = c.trim();
    if (trimmed.isEmpty) return;
    final alreadyAdded = _cities.any((existing) => existing.toLowerCase() == trimmed.toLowerCase());
    if (alreadyAdded) return;
    HapticFeedback.selectionClick();
    setState(() => _cities = [..._cities, trimmed]);
  }

  void _removeCity(String c) {
    HapticFeedback.selectionClick();
    setState(() => _cities = _cities.where((x) => x != c).toList());
  }

  bool get _valid => _goal.isNotEmpty && _roles.isNotEmpty;

  // Clears only the true *filter* facets — not Category/Goal, which are
  // identity fields bound to the profile (see this screen's own doc
  // comment above). The old implementation called setState(_hydrate),
  // which re-read every field — including Category/Goal — from the last
  // *saved* profile. Since those two rarely change, Reset would silently
  // revert Work mode/Employment type/Cities to whatever was saved last
  // time Apply was tapped rather than actually clearing them — often
  // producing no visible change at all, which read as "Reset is broken."
  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _workMode = null;
      _employmentType = null;
      _cities = [];
    });
  }

  Future<void> _apply() async {
    if (!_valid) return;
    setState(() => _loading = true);
    final prefs = JobPreferences(cities: _cities, workMode: _workMode, employmentType: _employmentType);
    await context.read<AppState>().updateProfile((current) => current.copyWith(goal: _goal, roles: _roles, preferences: prefs));
    if (!mounted) return;
    setState(() => _loading = false);
    // go(), not pop() — pop() after this screen's own await gap updates the
    // URL (confirmed via the browser's location hash) but leaves this
    // screen's widget tree on-screen, unpopped: the same silently-broken
    // pop() behavior already documented and worked around in
    // profile_edit_screen.dart's save flow. This screen is always reached
    // from Home's filter icon, so returning straight there is correct
    // regardless of how it was pushed.
    context.go('/tabs');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return AppPage(
        backLabel: 'Jobs',
        backFallback: '/tabs',
        title: 'Filter jobs',
        maxWidth: AppBreakpoints.readingWidth,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OpportunityFilterFields(
              roles: _roles,
              goal: _goal,
              workMode: _workMode,
              employmentType: _employmentType,
              cities: _cities,
              onPickRoles: _pickRoles,
              onSelectGoal: _selectGoal,
              onToggleWorkMode: _toggleWorkMode,
              onToggleEmploymentType: _toggleEmploymentType,
              onAddCity: _addCity,
              onRemoveCity: _removeCity,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                SizedBox(width: 140, child: PillButton(label: 'Reset', variant: PillVariant.secondary, onPressed: _reset)),
                const SizedBox(width: AppSpacing.md),
                SizedBox(width: 200, child: PillButton(label: 'Apply', onPressed: _valid ? _apply : null, loading: _loading, disabled: !_valid)),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        children: [
          const PageHeaderBar(title: 'Filter jobs'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                OpportunityFilterFields(
                  roles: _roles,
                  goal: _goal,
                  workMode: _workMode,
                  employmentType: _employmentType,
                  cities: _cities,
                  onPickRoles: _pickRoles,
                  onSelectGoal: _selectGoal,
                  onToggleWorkMode: _toggleWorkMode,
                  onToggleEmploymentType: _toggleEmploymentType,
                  onAddCity: _addCity,
                  onRemoveCity: _removeCity,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillButton(label: 'Apply', onPressed: _valid ? _apply : null, loading: _loading, disabled: !_valid),
                const SizedBox(height: AppSpacing.md),
                // De-emphasized on purpose, same treatment as "Clear
                // filters" elsewhere (college_feed_screen.dart,
                // courses_explore_screen.dart) — Reset is a minor, reversible
                // action and shouldn't visually compete with Apply.
                GestureDetector(
                  onTap: _reset,
                  child: Text('Reset', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                ),
              ],
            ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
