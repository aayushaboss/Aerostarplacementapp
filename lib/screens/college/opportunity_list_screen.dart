import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../mockData/mock_opportunities.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../models/user.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import 'package:flutter/services.dart';

import '../../mockData/mock_courses.dart';
import '../../models/course.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/badges.dart';
import '../../widgets/opportunity_detail_view.dart';
import '../../widgets/opportunity_filter_fields.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/sort_dropdown.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/opportunity_meta.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/responsive_body.dart';

/// The "View all" destination for a single carousel section on the browse
/// feed — same flat vertical list the feed used before it was split into
/// topics, just scoped to one category (or, with [category] null, sorted
/// purely by match — the "based on your profile" section's full list).
class OpportunityListScreen extends StatefulWidget {
  final String title;
  final String? category;

  /// Explicit opportunity IDs, in order — how a notification like "3 new
  /// internships match your goals" opens this screen scoped to exactly the
  /// roles it promised, instead of the generic profile-matched feed
  /// ([category] null) or a whole category. Takes priority over [category]
  /// when both are set.
  final List<String>? ids;

  /// Free-text search — the Home search bar's destination. Matches title /
  /// company / category / location via [filterOpportunities]. Takes priority
  /// over [category] when both are set (but not over [ids]).
  final String? query;

  const OpportunityListScreen({super.key, required this.title, this.category, this.ids, this.query});

  @override
  State<OpportunityListScreen> createState() => _OpportunityListScreenState();
}

class _OpportunityListScreenState extends State<OpportunityListScreen> {
  // Filters for the tablet and desktop layout. They start from what the student already told us
  // (their goal and cities) and the list this screen was opened for, and change only this
  // screen's results (nothing is saved to the profile from here).
  List<String> _roles = [];
  String _goal = 'both';
  String? _workMode;
  String? _employmentType;
  List<String> _cities = [];
  late String _query = widget.query ?? '';
  String _sort = 'match';
  String? _selectedId;
  int _limit = 30;
  Future<List<Opportunity>>? _future;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _roles = widget.category != null ? [widget.category!] : [];
    final goal = user?.goal;
    _goal = (goal == 'internship' || goal == 'job') ? goal! : 'both';
    _workMode = user?.preferences?.workMode;
    _employmentType = user?.preferences?.employmentType;
    _cities = List.of(user?.preferences?.cities ?? const []);
    _searchController.text = _query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount => (_roles.isNotEmpty ? 1 : 0) + (_goal != 'both' ? 1 : 0) + (_workMode != null ? 1 : 0) + (_employmentType != null ? 1 : 0) + _cities.length;

  Future<List<Opportunity>> _loadWide(User? user) async {
    final repo = context.read<Repositories>().opportunities;
    if (widget.ids != null) {
      return widget.ids!.map(repo.getOpportunityById).whereType<Opportunity>().toList();
    }
    final results = await repo.listOpportunities(
      type: _goal == 'internship' ? 'Internship' : (_goal == 'job' ? 'Full-time' : null),
      workMode: _workMode,
      employmentType: _employmentType,
      categories: _roles.isEmpty ? null : _roles,
      locations: _cities.isEmpty ? null : _cities,
      query: _query.trim().isEmpty ? null : _query,
    );
    final q = _query.trim().isEmpty ? null : _query;
    results.sort((a, b) {
      if (_sort == 'deadline') {
        final da = DateTime.tryParse(a.deadline);
        final db = DateTime.tryParse(b.deadline);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      }
      if (q != null) {
        final byRelevance = searchRelevance(b, q).compareTo(searchRelevance(a, q));
        if (byRelevance != 0) return byRelevance;
      }
      return b.matchScoreFor(user).compareTo(a.matchScoreFor(user));
    });
    return results;
  }

  void _refilter(VoidCallback change) {
    setState(() {
      change();
      _limit = 30;
      _selectedId = null;
      _future = null;
    });
  }

  void _resetFilters() {
    HapticFeedback.selectionClick();
    _refilter(() {
      _roles = [];
      _goal = 'both';
      _workMode = null;
      _employmentType = null;
      _cities = [];
    });
  }

  void _addCity(String c) {
    final t = c.trim();
    if (t.isEmpty || _cities.any((x) => x.toLowerCase() == t.toLowerCase())) return;
    _refilter(() => _cities = [..._cities, t]);
  }

  void _toggleRole(String r) => _refilter(() => _roles = _roles.contains(r) ? _roles.where((x) => x != r).toList() : [..._roles, r]);

  void _selectGoal(String g) => _refilter(() {
        _goal = g;
        if (g == 'internship') _employmentType = null;
      });

  Widget _filterFields({bool checklist = true, VoidCallback? onPickRoles}) {
    return OpportunityFilterFields(
      roles: _roles,
      goal: _goal,
      workMode: _workMode,
      employmentType: _employmentType,
      cities: _cities,
      categoryAsChecklist: checklist,
      dense: true,
      onToggleRole: _toggleRole,
      onPickRoles: onPickRoles ?? () {},
      onSelectGoal: _selectGoal,
      onToggleWorkMode: (m) => _refilter(() => _workMode = _workMode == m ? null : m),
      onToggleEmploymentType: (t) => _refilter(() => _employmentType = _employmentType == t ? null : t),
      onAddCity: _addCity,
      onRemoveCity: (c) => _refilter(() => _cities = _cities.where((x) => x != c).toList()),
    );
  }

  /// The filter sheet of the medium layout: slides in from the right (400px) over a dimmed page,
  /// with Reset and Apply in its footer. It edits a copy and applies it on Apply.
  Future<void> _openFilterSheet() async {
    var roles = List.of(_roles);
    var goal = _goal;
    var workMode = _workMode;
    var employmentType = _employmentType;
    var cities = List.of(_cities);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close filters',
      barrierColor: const Color(0x521C1C1E),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: AppColors.white,
          elevation: 0,
          child: SizedBox(
            width: 400,
            height: double.infinity,
            child: StatefulBuilder(
              builder: (context, setSheet) {
                return Column(
                  children: [
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      child: Row(
                        children: [
                          Expanded(child: Text('Filter jobs', style: AppTextStyles.h2.copyWith(color: AppColors.ink))),
                          GestureDetector(onTap: () => Navigator.of(dialogContext).pop(), child: const Icon(Ionicons.close, size: 24, color: AppColors.ink)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        child: OpportunityFilterFields(
                          roles: roles,
                          goal: goal,
                          workMode: workMode,
                          employmentType: employmentType,
                          cities: cities,
                          categoryAsChecklist: true,
                          onToggleRole: (r) => setSheet(() => roles = roles.contains(r) ? roles.where((x) => x != r).toList() : [...roles, r]),
                          onPickRoles: () {},
                          onSelectGoal: (g) => setSheet(() {
                            goal = g;
                            if (g == 'internship') employmentType = null;
                          }),
                          onToggleWorkMode: (m) => setSheet(() => workMode = workMode == m ? null : m),
                          onToggleEmploymentType: (t) => setSheet(() => employmentType = employmentType == t ? null : t),
                          onAddCity: (c) {
                            final t = c.trim();
                            if (t.isNotEmpty && !cities.any((x) => x.toLowerCase() == t.toLowerCase())) setSheet(() => cities = [...cities, t]);
                          },
                          onRemoveCity: (c) => setSheet(() => cities = cities.where((x) => x != c).toList()),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setSheet(() {
                              roles = [];
                              goal = 'both';
                              workMode = null;
                              employmentType = null;
                              cities = [];
                            }),
                            child: Text('Reset', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 160,
                            child: PillButton(
                              label: 'Apply',
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _refilter(() {
                                  _roles = roles;
                                  _goal = goal;
                                  _workMode = workMode;
                                  _employmentType = employmentType;
                                  _cities = cities;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim, _, child) => SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child),
    );
  }

  Widget _searchField() {
    return Container(
      width: 300,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        children: [
          const Icon(Ionicons.search_outline, size: 15, color: AppColors.gray500),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _refilter(() => _query = v),
              style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.ink),
              cursorColor: AppColors.ink,
              decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Search jobs, roles...', hintStyle: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray400)),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _refilter(() => _query = '');
              },
              child: const Icon(Ionicons.close_circle, size: 16, color: AppColors.gray400),
            ),
        ],
      ),
    );
  }

  Widget _sortControl() => SortDropdown(
        value: _sort,
        options: const [('match', 'Best match'), ('deadline', 'Deadline soonest')],
        onChanged: (v) => _refilter(() => _sort = v),
      );

  OpportunityDetailData _detailData(Opportunity o, AppState appState) {
    final similar = filterOpportunities(categories: [o.category]).where((x) => x.id != o.id).take(3).toList();
    final List<Course> prep = prepCoursesFor(o.prepCourses);
    final applied = context.read<Repositories>().applications.isOpportunityApplied(o.id);
    return OpportunityDetailData(
      opportunity: o,
      prepCourses: prep,
      similar: similar,
      user: appState.user,
      applied: applied,
      saved: appState.isOpportunitySaved(o.id),
      onApply: () {
        if (!applied) startApplyFlow(context, o, onApplied: () => setState(() {}));
      },
      onToggleSave: () => appState.toggleSavedOpportunity(o.id),
      onAskExpert: () => context.push('/booking?kind=placement'),
      onOpenSimilar: (s) => context.push('/opportunity/${s.id}'),
      onOpenCourse: (c) => context.push('/course/${c.id}'),
    );
  }

  /// One job in the list beside the detail pane: no Apply button here (Apply is in the pane), and
  /// the selected one gets the 2px yellow outline.
  Widget _masterCard(Opportunity o, AppState appState, User? user, {required bool selected}) {
    final applied = context.read<Repositories>().applications.isOpportunityApplied(o.id);
    final match = applied ? null : o.matchLabelFor(user);
    final deadline = applied ? null : o.deadlineLabel;
    return SurfaceCard(
      selected: selected,
      onTap: () => setState(() => _selectedId = o.id),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTag(label: o.type, compact: true),
              const Spacer(),
              GestureDetector(
                onTap: () => appState.toggleSavedOpportunity(o.id),
                child: Icon(appState.isOpportunitySaved(o.id) ? Ionicons.bookmark : Ionicons.bookmark_outline, size: 18, color: appState.isOpportunitySaved(o.id) ? AppColors.ink : AppColors.gray400),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(o.title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold))),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(o.company, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.location_outline, size: 13, color: AppColors.gray500), const SizedBox(width: AppSpacing.xs), Text(o.location, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))]),
                Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.cash_outline, size: 13, color: AppColors.gray500), const SizedBox(width: AppSpacing.xs), Text(o.stipend, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))]),
              ],
            ),
          ),
          if (match != null || deadline != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  if (match != null) ...[const Icon(Ionicons.star, size: 13, color: AppColors.ink), const SizedBox(width: AppSpacing.xs), Text(match, style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium)), const SizedBox(width: AppSpacing.md)],
                  if (deadline != null) ...[Icon(Ionicons.time_outline, size: 13, color: o.deadlineIsUrgent ? AppColors.error : AppColors.gray500), const SizedBox(width: AppSpacing.xs), Text(deadline, style: AppTextStyles.caption.copyWith(color: o.deadlineIsUrgent ? AppColors.error : AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))],
                ],
              ),
            ),
          if (applied) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('Applied', style: AppTextStyles.caption.copyWith(color: AppColors.successDark, fontSize: 12, fontWeight: AppFontWeight.medium))),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context, AppState appState, User? user) {
    final expanded = AppBreakpoints.isExpanded(context);
    _future ??= _loadWide(user);
    final hasQuery = _query.trim().isNotEmpty;

    return FutureBuilder<List<Opportunity>>(
      future: _future,
      builder: (context, snap) {
        final results = snap.data ?? const <Opportunity>[];
        final loading = snap.connectionState != ConnectionState.done;
        final subtitle = loading ? null : '${results.length} ${results.length == 1 ? 'opportunity' : 'opportunities'}';

        Widget empty() => Center(
              child: EmptyState(
                icon: hasQuery ? Ionicons.search_outline : Ionicons.briefcase_outline,
                title: hasQuery ? 'No matches found' : 'No openings here right now',
                subtitle: hasQuery || _activeFilterCount > 0 ? 'Try a different search term or clear a filter.' : 'Check back soon — new opportunities are added regularly.',
                buttonLabel: _activeFilterCount > 0 ? 'Clear filters' : null,
                onButtonTap: _activeFilterCount > 0 ? _resetFilters : null,
              ),
            );

        if (!expanded) {
          final cols = 2;
          final shown = results.take(_limit).toList();
          return AppPage(
            backLabel: 'Home',
            title: widget.title,
            subtitle: subtitle,
            actions: [
              if (widget.ids == null)
                GestureDetector(
                  onTap: _openFilterSheet,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
                    child: Row(children: [const Icon(Ionicons.options, size: 16, color: AppColors.ink), const SizedBox(width: 6), Text(_activeFilterCount > 0 ? 'Filters · $_activeFilterCount' : 'Filters', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.medium))]),
                  ),
                ),
              _sortControl(),
            ],
            body: loading
                ? const Padding(padding: EdgeInsets.only(top: AppSpacing.xxl), child: Center(child: CircularProgressIndicator(color: AppColors.ink)))
                : results.isEmpty
                    ? SizedBox(height: 360, child: empty())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppGrid(
                            columns: cols,
                            gap: AppSpacing.md,
                            children: [
                              for (final o in shown)
                                OpportunityRow(
                                  tag: o.type,
                                  title: o.title,
                                  subtitle: o.company,
                                  meta: opportunityMeta(o),
                                  matchLabel: o.matchLabelFor(user),
                                  deadlineLabel: o.deadlineLabel,
                                  deadlineUrgent: o.deadlineIsUrgent,
                                  saved: appState.isOpportunitySaved(o.id),
                                  applied: context.read<Repositories>().applications.isOpportunityApplied(o.id),
                                  onToggleSave: () => appState.toggleSavedOpportunity(o.id),
                                  onTap: () => context.push('/opportunity/${o.id}'),
                                  onApply: () => startApplyFlow(context, o, onApplied: () => setState(() {})),
                                ),
                            ],
                          ),
                          if (results.length > _limit)
                            Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: Center(child: PillButton(label: 'Show more (${results.length - _limit} more)', variant: PillVariant.secondary, full: false, onPressed: () => setState(() => _limit += 30)))),
                        ],
                      ),
          );
        }

        // Expanded: filters, the list, and the selected job's detail side by side.
        final selected = results.isEmpty ? null : results.firstWhere((o) => o.id == _selectedId, orElse: () => results.first);
        final shown = results.take(_limit).toList();
        return Material(
          color: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg - 4),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                child: PageHeader(backLabel: 'Home', title: widget.title, subtitle: subtitle, actions: [_searchField(), _sortControl()]),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.ids == null)
                      Container(
                        width: 240,
                        decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('Filters', style: AppTextStyles.h3.copyWith(color: AppColors.ink))),
                                  GestureDetector(onTap: _resetFilters, child: Text('Reset', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium))),
                                ],
                              ),
                              _filterFields(),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      width: 360,
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                      child: loading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
                          : results.isEmpty
                              ? empty()
                              : ListView(
                                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                                  children: [
                                    for (final o in shown) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _masterCard(o, appState, user, selected: selected?.id == o.id)),
                                    if (results.length > _limit) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: PillButton(label: 'Show more (${results.length - _limit} more)', variant: PillVariant.secondary, onPressed: () => setState(() => _limit += 30))),
                                  ],
                                ),
                    ),
                    Expanded(
                      child: selected == null
                          ? const SizedBox.shrink()
                          : OpportunityDetailPane(data: _detailData(selected, appState), onOpenFull: () => context.push('/opportunity/${selected.id}')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Already-applied openings stay in the list with a disabled "Applied ✓"
  // button rather than being filtered out. Loaded once per screen visit —
  // if the signed-in user's roles/resume change while this screen is still
  // open, the match-score sort below won't re-run until it's reopened;
  // an acceptable tradeoff for this pass (see AsyncValueView's own note on
  // not re-running its loader reactively).
  Future<List<Opportunity>> _load(User? user) async {
    final repo = context.read<Repositories>().opportunities;
    if (widget.ids != null) {
      return widget.ids!.map(repo.getOpportunityById).whereType<Opportunity>().toList();
    }
    final hasQuery = widget.query != null && widget.query!.trim().isNotEmpty;
    final results = await repo.listOpportunities(
      query: hasQuery ? widget.query : null,
      categories: (hasQuery || widget.category == null) ? null : [widget.category!],
    );
    // A search puts the closest answers first (title hits before company or city hits), then
    // the best profile match; a plain list is just by profile match.
    final q = hasQuery ? widget.query! : null;
    results.sort((a, b) {
      if (q != null) {
        final byRelevance = searchRelevance(b, q).compareTo(searchRelevance(a, q));
        if (byRelevance != 0) return byRelevance;
      }
      return b.matchScoreFor(user).compareTo(a.matchScoreFor(user));
    });
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final hasQuery = widget.query != null && widget.query!.trim().isNotEmpty;
    if (AppBreakpoints.isWide(context)) return _buildWide(context, appState, user);

    // 2 columns from tablet width up — a plain wider single-column cap (the
    // ResponsiveBody default) would just leave a card stretched thin down
    // the middle of the screen instead of actually using the extra room.
    final isTablet = AppBreakpoints.isWide(context);
    final columns = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium ? 2 : 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1200 : 720, child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  BackChevron(color: AppColors.ink, fallbackRoute: '/tabs'),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView<List<Opportunity>>(
                loader: () => _load(user),
                isEmpty: (results) => results.isEmpty,
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: EmptyState(
                      icon: hasQuery ? Ionicons.search_outline : Ionicons.briefcase_outline,
                      title: hasQuery ? 'No matches found' : 'No openings here right now',
                      subtitle: hasQuery
                          ? 'Try a different search term.'
                          : 'Check back soon — new opportunities are added regularly.',
                    ),
                  ),
                ),
                builder: (context, results) => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
                      // One row per `columns` cards, not one row per card —
                      // OpportunityRow sizes to its own content height
                      // (mainAxisSize.min), so a fixed-extent GridView risked
                      // either clipping the taller cards or leaving visible
                      // gaps under the shorter ones. A Row of Expanded cards
                      // just takes each row's natural tallest height instead.
                      itemCount: (results.length / columns).ceil(),
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, rowIndex) {
                        final start = rowIndex * columns;
                        final rowItems = results.skip(start).take(columns).toList();
                        Widget cardFor(Opportunity o) => OpportunityRow(
                              tag: o.type,
                              title: o.title,
                              subtitle: o.company,
                              meta: opportunityMeta(o),
                              matchLabel: o.matchLabelFor(user),
                              deadlineLabel: o.deadlineLabel,
                              deadlineUrgent: o.deadlineIsUrgent,
                              saved: appState.isOpportunitySaved(o.id),
                              applied: context.read<Repositories>().applications.isOpportunityApplied(o.id),
                              onToggleSave: () => appState.toggleSavedOpportunity(o.id),
                              onTap: () => context.push('/opportunity/${o.id}'),
                              onApply: () => startApplyFlow(context, o, onApplied: () => setState(() {})),
                            );
                        if (columns == 1) return cardFor(rowItems.first);
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < columns; i++) ...[
                                if (i > 0) const SizedBox(width: AppSpacing.lg),
                                Expanded(child: i < rowItems.length ? cardFor(rowItems[i]) : const SizedBox()),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ),
            // Only for the notification-scoped case: this screen is a dead
            // end otherwise (it's a push, not a tab), so a direct way back
            // to the feed matters more here than on the category views,
            // which the tab bar and back-chevron already cover well.
            if (widget.ids != null)
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, MediaQuery.of(context).padding.bottom + AppSpacing.md),
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.go('/tabs'),
                    child: Text(
                      'Back to home',
                      style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.semibold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      )),
    );
  }
}
