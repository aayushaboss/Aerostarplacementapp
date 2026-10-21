import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../mockData/mock_bookings.dart';
import '../../mockData/mock_courses.dart';
import '../../mockData/mock_notifications.dart';
import '../../mockData/mock_profile_options.dart';
import '../../mockData/related_roles.dart';
import '../../models/booking.dart';
import '../../models/job_preferences.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../models/user.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/group_by_category.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../shared/notifications_screen.dart' show openNotifications;
import '../../widgets/app_page.dart';
import '../../widgets/auto_carousel.dart';
import '../../widgets/grid_cards.dart';
import '../../widgets/home_top_bar.dart';
import '../../widgets/course_carousel_section.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/opportunity_carousel_section.dart';
import '../../widgets/opportunity_meta.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/sort_dropdown.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _firstName(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  return trimmed.isEmpty ? 'there' : trimmed.split(' ').first;
}

/// Mirrors frontend/src/screens/CollegeFeed.tsx (CollegeFeed).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class CollegeFeedScreen extends StatefulWidget {
  const CollegeFeedScreen({super.key});

  @override
  State<CollegeFeedScreen> createState() => _CollegeFeedScreenState();
}

class _CollegeFeedScreenState extends State<CollegeFeedScreen> {
  String _type = 'All';
  List<Opportunity> _opps = [];
  List<Booking> _bookings = [];
  bool _loading = true;
  final _scrollController = ScrollController();
  int _lastSeenDataVersion = -1;
  String _homeSort = 'match';
  // Consumed once, here, not read fresh in build() — a mid-session
  // rebuild (a filter change, a data refresh) shouldn't flip the header
  // back to the generic subtitle just because AppState's own flag was
  // already cleared by the first build.
  bool _justOnboarded = false;

  @override
  void initState() {
    super.initState();
    _justOnboarded = context.read<AppState>().consumeJustOnboarded();
    // Branch index 0 (Home) — see router.dart's StatefulShellRoute.
    ScrollToTopRegistry.register(0, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(0);
    _scrollController.dispose();
    super.dispose();
  }

  static String _typeForGoal(String? goal) {
    switch (goal) {
      case 'internship':
        return 'Internship';
      case 'job':
        return 'Full-time';
      default:
        return 'All';
    }
  }

  Future<void> _load() async {
    final user = context.read<AppState>().user;
    // Pre-filter to whatever the user told onboarding (or the filter
    // screen) they were looking for — choosing "Full-time" and landing on
    // a feed still showing internships (unfiltered) undoes the point of
    // asking. Recomputed fresh on every _load() call (not cached in
    // initState) so returning from the filter screen picks up a changed
    // goal without needing separate reactive plumbing.
    _type = _typeForGoal(user?.goal);
    final prefs = user?.preferences;
    // Already-applied postings stay in the feed (shown with a disabled
    // "Applied ✓" button, per direct feedback) rather than being filtered
    // out — vanishing on apply read as "did that work?".
    final results = await context.read<Repositories>().opportunities.listOpportunities(
      type: _type == 'All' ? null : _type,
      workMode: prefs?.workMode,
      employmentType: prefs?.employmentType,
      locations: prefs?.cities,
    );
    // Most-relevant-first, matching the user's selected roles/resume —
    // ties keep the original (curated) order via a stable sort.
    final scores = {for (final o in results) o.id: o.matchScoreFor(user)};
    results.sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));
    if (!mounted) return;
    setState(() {
      _rowLimit = _pageSize;
      _opps = results;
      _bookings = listBookings();
      _loading = false;
    });
  }

  String _prettyDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${_weekdayShort[d.weekday - 1]}, ${_monthShort[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }

  Future<void> _onRefresh() async => _load();

  // Reads _load() again on return (rather than making _type/preferences
  // reactive via context.watch) since the filter screen saves straight to
  // AppState and pops — a fresh imperative reload picks up whatever
  // changed without needing separate reactive plumbing duplicating what
  // _load() already does on every call.
  Future<void> _openFilter() async {
    await context.push('/college/opportunity-filter');
    if (mounted) _load();
  }

  // Clears only the facets that actually gate the flat-list view (work
  // mode / employment type / cities) — Category/Goal are edited from the
  // same filter screen but aren't part of "filtering" here (see build()'s
  // isFiltering comment), so they're deliberately left untouched.
  Future<void> _clearFilters() async {
    await context.read<AppState>().updateProfile((current) => current.copyWith(preferences: const JobPreferences()));
    _load();
  }

  // Clears exactly one active facet — used by the removable-chip row so a
  // single tap can undo just "Remote" or just one city without resetting
  // every other filter the way _clearFilters does. A fresh JobPreferences(...),
  // not copyWith — copyWith's `??` fallback can't null out a field.
  Future<void> _clearFacet({bool workMode = false, bool employmentType = false, String? city}) async {
    final prefs = context.read<AppState>().user?.preferences ?? const JobPreferences();
    final updated = JobPreferences(
      cities: city != null ? prefs.cities.where((c) => c != city).toList() : prefs.cities,
      workMode: workMode ? null : prefs.workMode,
      employmentType: employmentType ? null : prefs.employmentType,
    );
    await context.read<AppState>().updateProfile((current) => current.copyWith(preferences: updated));
    _load();
  }

  // Same pill-chip visual language as OpportunityFilterFields' own
  // _removableChip (blueA10 bg, blue label, close icon) — no shared widget
  // exists for it today, so this mirrors that convention rather than
  // introducing a new one for just this screen.
  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.blue, width: 2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Ionicons.close, size: 14, color: AppColors.blue),
          ],
        ),
      ),
    );
  }

  List<Widget> _activeFilterChips(JobPreferences prefs) {
    return [
      if (prefs.workMode != null) _activeFilterChip(prefs.workMode!, () => _clearFacet(workMode: true)),
      if (prefs.employmentType != null) _activeFilterChip(prefs.employmentType!, () => _clearFacet(employmentType: true)),
      for (final c in prefs.cities) _activeFilterChip(c, () => _clearFacet(city: c)),
    ];
  }

  // Cards held in each department row; the heading shows the real total and the
  // "View all" tile opens every job in that department.
  static const _sectionCap = 10;

  // The flat result lists (filtered view, desktop topic grid) build one row per
  // job. With 1,000 jobs that is far too many to build at once, so they show a
  // page at a time with a "Show more" button.
  static const _pageSize = 30;
  int _rowLimit = _pageSize;

  Widget _showMore(int total) {
    if (total <= _rowLimit) return const SizedBox.shrink();
    final left = total - _rowLimit;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: PillButton(
        label: 'Show more ($left more)',
        variant: PillVariant.secondary,
        onPressed: () => setState(() => _rowLimit += _pageSize),
      ),
    );
  }

  /// Naukri-style "browse by topic" instead of one long vertical scroll,
  /// which stops being usable once there are hundreds of postings — a
  /// top-matches row, then one row per role the user picked as interested
  /// during onboarding, then (for a student who picked few roles) a small
  /// number of "related field" rows backfilled from [relatedRoles], then a
  /// course-recommendation row to close the scroll. Only used when there's
  /// no active search — a typed query collapses back to a flat ranked
  /// list, matching how search results read everywhere else.
  ///
  /// The related-field backfill exists because picking just 1-2 roles used
  /// to leave the feed thin (profile-matches + 1-2 role rows, then a single
  /// unstructured "Explore more roles" dump of literally everything else).
  /// A student who hasn't told us much yet isn't well served by "only show
  /// what they said they want" — they often don't fully know yet, so
  /// nearby fields are worth surfacing, just clearly labeled as related
  /// rather than mixed in unsorted. The budget below is derived from how
  /// many role-specific rows already rendered, so a broadly-interested
  /// student who already picked several roles doesn't get padded further.

  List<Widget> _sections(List<Opportunity> opps, AppState appState, User? user) {
    final roles = validRoles(user?.roles);
    final sections = <Widget>[];
    final shownOpps = <Opportunity>[];

    void addSection(String title, List<Opportunity> items, {String? category}) {
      if (items.isEmpty) return;
      final capped = items.take(_sectionCap).toList();
      shownOpps.addAll(capped);
      // No manual inter-section gap here — CarouselSectionHeading (used by
      // OpportunityCarouselSection/CourseCarouselSection) now carries its
      // own top divider + clearance, so every section supplies its own
      // separation from the one above it.
      sections.add(OpportunityCarouselSection(
        title: title,
        opportunities: capped,
        totalCount: items.length,
        matchLabel: (o) => o.matchLabelFor(user),
        isApplied: (o) => context.read<Repositories>().applications.isOpportunityApplied(o.id),
        isSaved: (o) => appState.isOpportunitySaved(o.id),
        onTapCard: (o) => context.push('/opportunity/${o.id}'),
        onApply: (o) => startApplyFlow(context, o, onApplied: () => setState(() {})),
        onToggleSave: (o) => appState.toggleSavedOpportunity(o.id),
        onViewAll: () => context.push(Uri(
          path: '/opportunities',
          queryParameters: {'title': title, if (category != null) 'category': category},
        ).toString()),
      ));
    }

    // Fallback for the (post-onboarding, shouldn't-happen) no-roles case —
    // without it the feed would have no job sections at all.
    if (roles.isEmpty) {
      addSection('Jobs for you', opps);
    }

    for (final role in roles) {
      final inRole = opps.where((o) => o.category.toLowerCase() == role.toLowerCase()).toList();
      addSection(role, inRole, category: role);
    }

    // Every other department gets its own row too, after the user's own, so all
    // 1,000 jobs are reachable from Home (each row's "View all" opens that whole
    // department). Previously only the chosen roles plus a few related ones showed.
    for (final dept in mockAllRoles) {
      if (roles.contains(dept)) continue;
      final inDept = opps.where((o) => o.category == dept).toList();
      addSection(dept, inDept, category: dept);
    }

    // Closes the scroll instead of just stopping — courses tied to
    // whatever the student actually saw above (via each opportunity's own
    // curated prepCourses), not a fragile category-string match against
    // Course.category, which uses a different vocabulary entirely.
    // take: 5 (not the function's own default of 4) — CourseCarouselSection's
    // trailing "View all" tile only ever renders once there are >=5 items,
    // so the default cap made it permanently unreachable here specifically.
    final upskillCourses = prepCoursesForOpportunities(shownOpps, take: 5);
    if (upskillCourses.isNotEmpty) {
      sections.add(CourseCarouselSection(
        // Explicitly says "courses" — "Boost your chances" gave no signal
        // this section was a different content type from the job carousels
        // right above it, and with an identical card shell, that left the
        // heading as the only thing that could have disambiguated it.
        title: 'Courses to boost your profile',
        courses: upskillCourses,
        onViewAll: () => context.go('/tabs/explore'),
      ));
    }

    return sections;
  }

  // Used by the filtered flat-list view (see _groupedOppRows).
  List<Opportunity> _sortOpps(List<Opportunity> opps, User? user) {
    final sorted = List<Opportunity>.of(opps);
    if (_homeSort == 'deadline') {
      sorted.sort((a, b) {
        final da = DateTime.tryParse(a.deadline);
        final db = DateTime.tryParse(b.deadline);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    } else {
      final scores = {for (final o in sorted) o.id: o.matchScoreFor(user)};
      sorted.sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));
    }
    return sorted;
  }

  Widget _oppRow(BuildContext context, AppState appState, User? user, Opportunity o) {
    return OpportunityRow(
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
      heroTag: 'opportunity-${o.id}',
    );
  }

  // One card per row below tablet width, 2 at tablet, 3 at desktop — same
  // IntrinsicHeight/Expanded row-pairing opportunity_list_screen.dart
  // already uses (not GridView: OpportunityRow sizes to its own content
  // height via mainAxisSize.min, so a fixed-extent GridView would clip
  // taller cards or leave gaps under shorter ones). Chunked per category
  // group in _groupedOppRows below, so a partial last row only pads out
  // within its own group, not across group boundaries.
  List<Widget> _rowsChunked(BuildContext context, AppState appState, User? user, List<Opportunity> items, int columns) {
    if (columns == 1) {
      return [for (final o in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: _oppRow(context, appState, user, o))];
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      final rowItems = items.skip(i).take(columns).toList();
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(child: c < rowItems.length ? _oppRow(context, appState, user, rowItems[c]) : const SizedBox()),
              ],
            ],
          ),
        ),
      ));
    }
    return rows;
  }

  // Groups the isFiltering flat list by category whenever it spans more
  // than one — unlike the unfiltered view above (already one carousel per
  // selected role), this filter (work mode/employment type/city) never
  // scopes _opps by category at all, so it can freely interleave Software/
  // Design/Data/etc. results with nothing to browse just one category in
  // one continuous run. No explicit "selected categories" list exists on
  // this filter path (unlike Courses'), so groups are ordered by first
  // appearance in _opps instead.
  List<Widget> _groupedOppRows(BuildContext context, AppState appState, User? user, List<Opportunity> unsorted) {
    final opps = _sortOpps(unsorted, user);
    final width = MediaQuery.sizeOf(context).width;
    // 1 at desktop, not 3 — matches the unfiltered tabs+grid view's own
    // fix (see _desktopTopicGrid's comment): OpportunityRow's single-line
    // title truncates hard in a narrow column, and the filter panel here
    // already eats real width too. A full-width row per card reads as a
    // clean list instead.
    final columns = width >= AppBreakpoints.medium ? 1 : (width >= AppBreakpoints.medium ? 2 : 1);
    final shownOpps = opps.take(_rowLimit).toList();
    final categories = {for (final o in shownOpps) o.category}.toList();
    if (categories.length <= 1) {
      return [..._rowsChunked(context, appState, user, shownOpps, columns), _showMore(opps.length)];
    }
    final grouped = groupByCategory<Opportunity>(shownOpps, (o) => o.category);
    return [
      for (final entry in grouped.entries) ...[
        // top: lg matches courses_explore_screen.dart's _categoryHeading
        // vertical rhythm exactly — no horizontal value needed here (unlike
        // that self-contained version) since this heading already sits
        // inside the same horizontal-xl Padding the cards do.
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Text('${entry.key} (${entry.value.length})', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 16)),
        ),
        ..._rowsChunked(context, appState, user, entry.value, columns),
      ],
      _showMore(opps.length),
    ];
  }

  // ---------------------------------------------------------------------------------------------
  // Tablet and desktop layout. The phone layout in build() below is unchanged.
  // ---------------------------------------------------------------------------------------------

  /// The sections shown on Home: the student's own departments first, then the rest, each with
  /// every job in it (the heading shows the real total; "View all" opens the whole department).
  List<({String title, String? category, List<Opportunity> items})> _wideSectionData(List<Opportunity> opps, User? user) {
    final roles = validRoles(user?.roles);
    final out = <({String title, String? category, List<Opportunity> items})>[];
    if (roles.isEmpty) {
      if (opps.isNotEmpty) out.add((title: 'Jobs for you', category: null, items: opps));
    }
    for (final role in roles) {
      final inRole = opps.where((o) => o.category.toLowerCase() == role.toLowerCase()).toList();
      if (inRole.isNotEmpty) out.add((title: role, category: role, items: inRole));
    }
    for (final dept in mockAllRoles) {
      if (roles.contains(dept)) continue;
      final inDept = opps.where((o) => o.category == dept).toList();
      if (inDept.isNotEmpty) out.add((title: dept, category: dept, items: inDept));
    }
    return out;
  }

  Widget _wideJobCard(Opportunity o, AppState appState, User? user, {required bool compact}) {
    final applied = context.read<Repositories>().applications.isOpportunityApplied(o.id);
    return OpportunityGridCard(
      title: o.title,
      company: o.company,
      location: o.location,
      stipend: o.stipend,
      tag: o.type,
      compact: compact,
      matchLabel: applied ? null : o.matchLabelFor(user),
      deadlineLabel: applied ? null : o.deadlineLabel,
      deadlineUrgent: o.deadlineIsUrgent,
      applied: applied,
      saved: appState.isOpportunitySaved(o.id),
      onTap: () => context.push('/opportunity/${o.id}'),
      onApply: () => startApplyFlow(context, o, onApplied: () => setState(() {})),
      onToggleSave: () => appState.toggleSavedOpportunity(o.id),
    );
  }

  Widget _widePromoCard({required String title, required String body, required IconData icon, required VoidCallback onTap, required bool compact}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 112,
          padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.lg : AppSpacing.xl, vertical: AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, height: 1.3)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.3)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(icon, size: compact ? 28 : 32, color: AppColors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideUpcoming(Booking upcoming) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/tabs/sessions'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.xl), border: const Border(left: BorderSide(color: AppColors.blue, width: 4))),
          child: Row(
            children: [
              Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle), child: const Icon(Ionicons.videocam, size: 22, color: AppColors.ink)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UPCOMING SESSION', style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(upcoming.kind == 'placement' ? (upcoming.sessionType ?? 'Placement session') : 'Counseling with ${upcoming.counselor}', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text('${_prettyDate(upcoming.date)} • ${upcoming.time} • ${upcoming.mode == 'online' ? 'Online' : 'Offline'}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context, AppState appState, User? user, {required bool isFiltering, required JobPreferences? prefs, required Booking? upcoming}) {
    final expanded = AppBreakpoints.isExpanded(context);
    final compact = !expanded;
    final columns = AppBreakpoints.gridColumns(context);
    final gap = expanded ? AppSpacing.lg : AppSpacing.md;
    final unread = appState.hasUnreadNotifications(mockNotifications.map((n) => n.id).toList());

    final searchField = HomeSearchBar(height: expanded ? 44 : 54);
    final filterButton = HomeCircleButton(icon: isFiltering ? Ionicons.options : Ionicons.options_outline, size: expanded ? 44 : 54, label: 'Filter', dot: isFiltering, dotColor: AppColors.blue, onTap: _openFilter);

    Widget body() {
      if (_loading) {
        return const Padding(padding: EdgeInsets.only(top: AppSpacing.xl), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 180, height: 18), SizedBox(height: AppSpacing.lg), SkeletonBox(width: double.infinity, height: 260)]));
      }
      final children = <Widget>[];

      // The two promo cards sit side by side, static (the phone swaps them in a carousel).
      if (upcoming != null) {
        children.add(_wideUpcoming(upcoming));
      } else {
        children.add(AppGrid(
          columns: 2,
          gap: gap,
          children: [
            _widePromoCard(title: 'Talk to a placement expert', body: '1:1 guidance to land your next role.', icon: Ionicons.chatbubble_ellipses, compact: compact, onTap: () => context.push('/booking?kind=placement')),
            _widePromoCard(title: 'Get recruiters to notice you', body: compact ? 'Free 10-min test, attached to your resume.' : 'Free 10-min test, attached to your resume for recruiters.', icon: Ionicons.eye, compact: compact, onTap: () => context.go('/tabs/career-dna')),
          ],
        ));
      }

      if (_opps.isEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: EmptyState(
            icon: Ionicons.briefcase_outline,
            title: 'No opportunities match your filters',
            subtitle: 'Try widening your search or clearing a filter to see more.',
            buttonLabel: isFiltering ? 'Clear filters' : null,
            onButtonTap: isFiltering ? _clearFilters : null,
          ),
        ));
      } else if (isFiltering) {
        final sorted = _sortOpps(_opps, user);
        final shown = sorted.take(_rowLimit).toList();
        children.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Row(
            children: [
              Expanded(child: Text('${_opps.length} ${_opps.length == 1 ? 'opportunity' : 'opportunities'} found', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13, fontWeight: AppFontWeight.medium))),
              SortDropdown(value: _homeSort, options: const [('match', 'Best match'), ('deadline', 'Deadline soonest')], onChanged: (v) => setState(() => _homeSort = v)),
              const SizedBox(width: AppSpacing.lg),
              MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: _clearFilters, child: Text('Clear filters', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)))),
            ],
          ),
        ));
        if (prefs != null && !prefs.isEmpty) {
          children.add(Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: _activeFilterChips(prefs))));
        }
        final grouped = groupByCategory<Opportunity>(shown, (o) => o.category);
        for (final entry in grouped.entries) {
          if (grouped.length > 1) children.add(SectionHeading(title: entry.key, count: entry.value.length, padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md)));
          children.add(Padding(
            padding: EdgeInsets.only(top: grouped.length > 1 ? 0 : AppSpacing.md),
            child: AppGrid(columns: columns, gap: gap, children: [for (final o in entry.value) _wideJobCard(o, appState, user, compact: compact)]),
          ));
        }
        if (sorted.length > _rowLimit) {
          children.add(Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: Align(alignment: Alignment.center, child: PillButton(label: 'Show more (${sorted.length - _rowLimit} more)', variant: PillVariant.secondary, full: false, onPressed: () => setState(() => _rowLimit += _pageSize)))));
        }
      } else {
        // One section per department: the first row of cards (3 across, or 2x2 on a medium
        // window) and a "View all" link in the heading; no sideways scrolling.
        final take = expanded ? columns : 4;
        final shownOpps = <Opportunity>[];
        for (final sec in _wideSectionData(_opps, user)) {
          final cards = sec.items.take(take).toList();
          shownOpps.addAll(cards);
          children.add(SectionHeading(
            title: sec.title,
            count: sec.items.length,
            padding: EdgeInsets.only(top: expanded ? AppSpacing.xxl - 8 : AppSpacing.xl, bottom: AppSpacing.md),
            onViewAll: () => context.push(Uri(path: '/opportunities', queryParameters: {'title': sec.title, if (sec.category != null) 'category': sec.category!}).toString()),
          ));
          children.add(AppGrid(columns: columns, gap: gap, children: [for (final o in cards) _wideJobCard(o, appState, user, compact: compact)]));
        }
        final upskill = prepCoursesForOpportunities(shownOpps, take: columns);
        if (upskill.isNotEmpty) {
          children.add(SectionHeading(title: 'Courses to boost your profile', padding: EdgeInsets.only(top: expanded ? AppSpacing.xxl - 8 : AppSpacing.xl, bottom: AppSpacing.md), onViewAll: () => context.go('/tabs/explore')));
          children.add(AppGrid(columns: columns, gap: gap, children: [for (final c in upskill) CourseGridCard(course: c, onTap: () => context.push('/course/${c.id}'))]));
        }
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    }

    final gutter = AppBreakpoints.gutter(context);
    return Material(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expanded)
            HomeTopBar(
              search: searchField,
              onFilter: _openFilter,
              filtering: isFiltering,
              unread: unread,
              name: user?.name,
              photoUrl: user?.photoUrl,
              onBell: () => openNotifications(context),
              onAvatar: () => context.go('/tabs/profile'),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: AppBreakpoints.maxContentFor(context)),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xl, gutter, AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_justOnboarded ? 'Welcome, ${_firstName(user?.name)}' : 'Find your next role', style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                        Text(user?.name ?? 'Student', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                        if (!expanded)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Row(children: [Expanded(child: searchField), const SizedBox(width: AppSpacing.sm), filterButton]),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        body(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final appState = context.watch<AppState>();
    // A booking made/cancelled on the Sessions screen (or an application
    // deleted on the Applications tab), both kept alive in the background,
    // otherwise wouldn't update this screen's Upcoming Session card or
    // Applied badges until a manual pull-to-refresh.
    if (appState.dataVersion != _lastSeenDataVersion) {
      _lastSeenDataVersion = appState.dataVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    // Work mode / employment type / preferred cities have no home in the
    // sectioned carousel view below, unlike Category/Goal (which already
    // reshape it via _sections()'s per-role rows and _load()'s own type
    // filter) — so only these three facets trigger the flat-list swap.
    // Category alone can't sensibly trigger it: User.roles has no separate
    // "unfiltered" state to compare against (it's always "whatever the
    // user is currently interested in"), so treating it as a filter flag
    // would mean this almost never shows the sectioned view at all for any
    // onboarded user.
    final prefs = user?.preferences;
    final isFiltering = prefs != null && (prefs.workMode != null || prefs.employmentType != null || prefs.cities.isNotEmpty);
    final isTablet = AppBreakpoints.isWide(context);
    // _bookings is sorted ascending by real date/time, but nothing
    // previously excluded a session whose date had already passed — a
    // lapsed booking could sit in this "upcoming" slot indefinitely.
    final now = DateTime.now();
    final upcoming = _bookings.cast<Booking?>().firstWhere(
          (b) {
            final dt = parseBookingDateTime(b!.date, b.time);
            return dt == null || dt.isAfter(now);
          },
          orElse: () => null,
        );

    if (AppBreakpoints.isWide(context)) {
      return _buildWide(context, appState, user, isFiltering: isFiltering, prefs: prefs, upcoming: upcoming);
    }

    // The slim top bar (avatar/greeting/bell) plus a single pinned search
    // bar + filter row stay fixed above the scroll; everything else scrolls.
    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            HomeHeader(
              name: user?.name,
              photoUrl: user?.photoUrl,
              // A brand-new arrival gets a one-time personalized welcome
              // instead of the permanent generic subtitle every other
              // visit shows — previously this app had literally no
              // difference between a first open and a hundredth.
              subtitle: _justOnboarded ? 'Welcome, ${_firstName(user?.name)}' : 'Find your next role',
              onAvatarTap: () => context.go('/tabs/profile'),
              onBellTap: () => openNotifications(context),
              unread: appState.hasUnreadNotifications(
                mockNotifications.map((n) => n.id).toList(),
              ),
            ),
            Padding(
              // Bottom tightened from xl (32) — stacked under HomeHeader's
              // own (also-tightened) bottom inset, 32+32 read as a lot of
              // dead space between the header and the first real content
              // (the promo carousel) above the fold.
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md),
              child: Row(
                children: [
                  const Expanded(child: HomeSearchBar()),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    button: true,
                    label: 'Filter',
                    child: GestureDetector(
                      onTap: _openFilter,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                            child: Icon(
                              isFiltering ? Ionicons.options : Ionicons.options_outline,
                              size: 20,
                              color: isFiltering ? AppColors.blue : AppColors.ink,
                            ),
                          ),
                          if (isFiltering)
                            Positioned(
                              top: 10,
                              right: 11,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppColors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.offWhite, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _loading
                  ? ListView(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          child: SkeletonBox(width: 180, height: 18),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 290 + AppShadows.cardBuffer * 2,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppShadows.cardBuffer, AppSpacing.lg, AppShadows.cardBuffer),
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            children: const [
                              SkeletonCarouselCard(),
                              SizedBox(width: AppSpacing.md),
                              SkeletonCarouselCard(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      color: AppColors.blue,
                      onRefresh: _onRefresh,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: AppSpacing.xxxl + AppSpacing.xl),
                        children: [
                          // The search bar + filter row is pinned above this
                          // list (a Column sibling), not a scroll item.
                          // Bookings is no longer its own bottom tab (only
                          // reachable from Profile now), so a booked
                          // placement session needs a reminder here too —
                          // otherwise it's effectively invisible until the
                          // day of.
                          if (upcoming != null) ...[
                            GestureDetector(
                              onTap: () => context.go('/tabs/sessions'),
                              child: Container(
                                // No bottom margin — HomeDashboardCards' own
                                // leading shadow buffer (AppShadows.cardBuffer)
                                // already provides the gap to here; adding
                                // one on top of the other read as a
                                // noticeably looser gap than every other
                                // section-to-section gap on this screen.
                                margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 0),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.offWhite,
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  border: const Border(left: BorderSide(color: AppColors.blue, width: 4)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                                      child: const Icon(Ionicons.videocam, size: 22, color: AppColors.blue),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('UPCOMING SESSION', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
                                          Padding(
                                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                                            child: Text(
                                              upcoming.kind == 'placement' ? (upcoming.sessionType ?? 'Placement session') : 'Counseling with ${upcoming.counselor}',
                                              style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.bold),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                                            child: Text(
                                              '${_prettyDate(upcoming.date)} • ${upcoming.time} • ${upcoming.mode == 'online' ? 'Online' : 'Offline'}',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (upcoming == null) ...[
                            // Auto-swiping 2-card carousel — card 1 is the
                            // original standing "book a session" CTA, card 2
                            // hooks users into the free Level 1 Career Quiz
                            // test. Both cards now share one exact shape
                            // (title, 1 line if it fits; subtitle, up to 2
                            // lines) so a card's content can never overflow
                            // the carousel's fixed page height — the
                            // previous card 2 (a 3-line title+subtitle+
                            // italic-tagline stack) could exceed it at
                            // narrow widths, which clipped its last line and
                            // read as a broken/misaligned card. `alignment:
                            // centerLeft` on each Container vertically
                            // centers whatever content height actually
                            // renders within the fixed page, so a shorter
                            // render (e.g. a 1-line title) doesn't look
                            // pinned to the top with dead space below it.
                            // Both titles go through noOrphan() — without
                            // it, a wrapped title could strand a single
                            // word alone on its own line.
                            AutoCarousel(
                              // Sleek — just enough for a 2-line title + a
                              // 2-line body with tight vertical padding.
                              // alignment.centerLeft on each card keeps
                              // shorter content vertically centred.
                              height: 112,
                              // Longer than AutoCarousel's own 5s default —
                              // this card's 2-line title + 2-line body needs
                              // more time to actually read before it swaps.
                              interval: const Duration(seconds: 8),
                              cards: [
                                GestureDetector(
                                  onTap: () => context.push('/booking?kind=placement'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                noOrphan('Talk to a placement expert'),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 16, fontWeight: AppFontWeight.bold),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                                child: Text(
                                                  noOrphan('1:1 guidance to land your next role.'),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // A distinct semantic icon per card (was
                                        // the same generic arrow on both, which
                                        // made the two cards read as identical).
                                        const Icon(Ionicons.chatbubble_ellipses, size: 32, color: AppColors.yellow),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/tabs/career-dna'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Direct about the outcome (getting
                                              // noticed) with the concrete
                                              // mechanic in the body — the free
                                              // test is attached to the resume
                                              // recruiters see.
                                              Text(
                                                noOrphan('Get recruiters to notice you'),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 16, fontWeight: AppFontWeight.bold),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                                child: Text(
                                                  noOrphan('Free 10-min test, attached to your resume for recruiters.'),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 12, height: 1.3),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Ionicons.eye, size: 32, color: AppColors.yellow),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_opps.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(top: AppSpacing.xxxl),
                              child: EmptyState(
                                icon: Ionicons.briefcase_outline,
                                title: 'No opportunities match your filters',
                                subtitle: 'Try widening your search or clearing a filter to see more.',
                                buttonLabel: isFiltering ? 'Clear filters' : null,
                                onButtonTap: isFiltering ? _clearFilters : null,
                              ),
                            )
                          else if (isFiltering)
                            Padding(
                              // Same fix as the unfiltered branch below —
                              // AppSpacing.xl, matching the gap above
                              // HomeDashboardCards' nudge banner.
                              padding: const EdgeInsets.only(top: AppSpacing.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${_opps.length} ${_opps.length == 1 ? 'opportunity' : 'opportunities'} found',
                                            style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                                          ),
                                        ),
                                        // Sort used to only ever live in
                                        // _desktopTopicGrid's own header,
                                        // which this branch replaces
                                        // entirely — so applying a facet
                                        // filter (work mode/employment
                                        // type/city) silently removed the
                                        // sort control altogether. Shown
                                        // here too now, wired to the same
                                        // _homeSort state and (via
                                        // _sortOpps) the same sorting
                                        // _groupedOppRows now applies.
                                        if (isTablet) ...[
                                          SortDropdown(
                                            value: _homeSort,
                                            options: const [('match', 'Best match'), ('deadline', 'Deadline soonest')],
                                            onChanged: (v) => setState(() => _homeSort = v),
                                          ),
                                          const SizedBox(width: AppSpacing.lg),
                                        ],
                                        GestureDetector(
                                          onTap: _clearFilters,
                                          child: Text('Clear filters', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isTablet && !prefs.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                                      child: Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: AppSpacing.sm,
                                        children: _activeFilterChips(prefs),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                                    child: Column(
                                      // Column defaults to centering its
                                      // children — harmless for the
                                      // full-width OpportunityRow cards, but
                                      // it was silently centering the plain
                                      // Text category headings too, unlike
                                      // Courses' equivalent (a direct
                                      // ListView child, naturally
                                      // left-aligned). .start matches that.
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _groupedOppRows(context, appState, user, _opps),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // No manual top gap here — the first carousel's
                            // own CarouselSectionHeading already supplies a
                            // divider + AppSpacing.xl clearance above it.
                            Column(children: _sections(_opps, appState, user)),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      )),
    );
  }
}
