import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories.dart';
import '../../mockData/mock_courses.dart';
import '../../models/application.dart';
import '../../models/course.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/applications_swipe_hint_prefs_key.dart';
import '../../utils/no_orphan.dart';
import '../../utils/relative_time.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/app_page.dart';
import '../../widgets/badges.dart';
import '../../widgets/category_tab_bar.dart';
import '../../widgets/company_mark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/prep_course_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/sort_dropdown.dart';
import '../../widgets/stat_tile.dart';
import 'application_detail_screen.dart' show ApplicationDetailView;
import '../../widgets/adaptive_sheet.dart';

/// Shared "prep for this" bottom sheet — the momentum banner opens it scoped
/// to every role applied for, each card's own "Q&A" shortcut opens it scoped
/// to just that one role, so the sheet itself only exists once.
void _showPrepSheet(BuildContext context, List<Course> courses, {required String heading, required String subtitle}) {
  showAdaptiveSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(sheetContext).padding.bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xs,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(heading, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
            child: Text(
              noOrphan(subtitle),
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
            ),
          ),
          ...courses.map((c) => PrepCourseCard(
                course: c,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/course/${c.id}');
                },
              )),
          PillButton(
            label: 'Browse all courses',
            variant: PillVariant.ghost,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              context.go('/tabs/explore');
            },
          ),
        ],
      ),
    ),
  );
}

/// Mirrors frontend/src/screens/ApplicationsTracker.tsx (ApplicationsTracker).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class ApplicationsTrackerScreen extends StatefulWidget {
  const ApplicationsTrackerScreen({super.key});

  @override
  State<ApplicationsTrackerScreen> createState() => _ApplicationsTrackerScreenState();
}

class _ApplicationsTrackerScreenState extends State<ApplicationsTrackerScreen> {
  List<Application> _apps = [];
  // False until the first load finishes, so the wide layout does not flash "No applications yet" first.
  bool _loaded = false;
  int _lastSeenDataVersion = -1;
  final _scrollController = ScrollController();
  // Desktop-only controls (see _desktopBody) — mobile/tablet never read
  // these, so they can't affect anything below AppBreakpoints.medium.
  String _statusFilter = 'All';
  String _appsSort = 'newest';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // Branch index 1 (college's Browse/Applications tab) — this screen is
    // college-only, see BrowseTabScreen.
    ScrollToTopRegistry.register(1, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(1);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Buckets the 5 real StatusBadge statuses into the 3 groups the
  // reference's stat tiles/tabs use — real data, just a grouping decision
  // (not a new status concept; `Application.status` itself is untouched).
  static bool _isInProgress(Application a) => a.status == 'Applied' || a.status == 'In Review' || a.status == 'Interview';
  static bool _isOffer(Application a) => a.status == 'Offer';
  static bool _isNotSelected(Application a) => a.status == 'Rejected';

  List<Application> _bucketFor(String key) {
    switch (key) {
      case 'In Progress':
        return _apps.where(_isInProgress).toList();
      case 'Offers':
        return _apps.where(_isOffer).toList();
      case 'Not Selected':
        return _apps.where(_isNotSelected).toList();
      default:
        return _apps;
    }
  }

  List<Application> get _visibleApps {
    var list = _bucketFor(_statusFilter);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) => a.opportunity.title.toLowerCase().contains(q) || a.opportunity.company.toLowerCase().contains(q)).toList();
    }
    final sorted = List<Application>.of(list);
    sorted.sort((a, b) {
      final da = DateTime.tryParse(a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _appsSort == 'oldest' ? da.compareTo(db) : db.compareTo(da);
    });
    return sorted;
  }

  Future<void> _load() async {
    final apps = await context.read<Repositories>().applications.listApplications();
    if (mounted) setState(() {
      _apps = apps;
      _loaded = true;
    });
  }

  Future<void> _onRefresh() async => _load();

  Future<void> _removeApplication(Application a) async {
    // Soft delete — the entry moves to Recently Deleted rather than
    // vanishing outright, so this SnackBar's Undo is now just the fast
    // path for the immediate "oops"; the trash icon in the header above is
    // the longer-lived backstop if this toast is missed. Both call the
    // same restoreApplication(id).
    final repo = context.read<Repositories>().applications;
    await repo.removeApplication(a.id);
    await _load();
    if (!mounted) return;
    // Other kept-alive tabs (Home's Applied badges) only recompute from
    // listApplications() on their own next build — bump so they notice
    // this change instead of showing a stale Applied state.
    context.read<AppState>().bumpDataVersion();
    // Removing more than one card back-to-back otherwise queues a fresh
    // SnackBar behind whichever one is still showing (ScaffoldMessenger's
    // default) instead of replacing it — each 4s toast waits for the last
    // to finish, which reads as one that never goes away. Clear first so
    // the newest removal always replaces, never queues.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${a.opportunity.title}'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.yellow,
            onPressed: () async {
              await repo.restoreApplication(a.id);
              await _load();
              if (!mounted) return;
              context.read<AppState>().bumpDataVersion();
            },
          ),
          duration: const Duration(seconds: 4),
          // See sessions_screen.dart's own note — `persist` defaults to
          // true whenever `action` is set, silently making `duration` a
          // no-op unless this is set explicitly.
          persist: false,
        ),
      );
  }

  // ---------------------------------------------------------------------------------------------
  // Tablet and desktop layout. The phone layout in build() below is unchanged.
  // ---------------------------------------------------------------------------------------------

  Widget _statusTabs() => CategoryTabBar(
        tabs: [
          CategoryTab(key: 'All', label: 'All', count: _apps.length),
          CategoryTab(key: 'In Progress', label: 'In Progress', count: _bucketFor('In Progress').length),
          CategoryTab(key: 'Offers', label: 'Offers', count: _bucketFor('Offers').length),
          CategoryTab(key: 'Not Selected', label: 'Not Selected', count: _bucketFor('Not Selected').length),
        ],
        selected: _statusFilter,
        onSelected: (key) => setState(() => _statusFilter = key),
      );

  Widget _recentlyDeletedButton({required bool labelled}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/applications/recently-deleted'),
        child: Container(
          height: 44,
          width: labelled ? null : 44,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: labelled ? AppSpacing.md : 0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border, width: 1.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Ionicons.trash_outline, size: 16, color: AppColors.gray500),
              if (labelled) ...[const SizedBox(width: 6), Text('Recently deleted', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13, fontWeight: AppFontWeight.medium))],
            ],
          ),
        ),
      ),
    );
  }

  /// One application in the list beside the detail pane: a flat row, no card. The selected one gets
  /// the 2px yellow outline.
  Widget _masterRow(Application a, {required bool selected}) {
    final applied = relativeTimeLabel(DateTime.tryParse(a.createdAt) ?? DateTime.now());
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedId = a.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md - 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              CompanyMark(company: a.opportunity.company, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.opportunity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('${a.opportunity.company} · $applied', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))),
                    Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: StatusBadge(status: a.status)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A compact search box for the page header (the shared PillInput is a 54px form field).
  Widget _searchField() {
    return SizedBox(
      width: 260,
      height: 44,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search applications',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14),
          prefixIcon: const Icon(Ionicons.search_outline, size: 18, color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.offWhite,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
        ),
      ),
    );
  }

  String _summaryLine() {
    final offers = _bucketFor('Offers').length;
    final inProgress = _bucketFor('In Progress').length;
    final parts = <String>['${_apps.length} application${_apps.length != 1 ? 's' : ''}'];
    if (offers > 0) parts.add('$offers offer${offers != 1 ? 's' : ''}');
    if (inProgress > 0) parts.add('$inProgress in progress');
    return parts.join(' · ');
  }

  Widget _buildWide(BuildContext context, List<Application> displayApps) {
    if (!_loaded) return const Material(color: AppColors.white, child: SizedBox.expand());
    final expanded = AppBreakpoints.isExpanded(context);
    final gutter = AppBreakpoints.gutter(context);
    final hasApps = _apps.isNotEmpty;

    final emptyState = !hasApps
        ? EmptyState(icon: Ionicons.paper_plane_outline, title: 'No applications yet', subtitle: "Explore opportunities and apply — they'll show up here.", buttonLabel: 'Explore opportunities', onButtonTap: () => context.go('/tabs'))
        : const EmptyState(icon: Ionicons.search_outline, title: 'No applications match', subtitle: 'Try a different search or clear the status filter.');

    final controls = <Widget>[
      if (hasApps) ...[
        _searchField(),
        SortDropdown(height: 44, value: _appsSort, options: const [('newest', 'Newest applied'), ('oldest', 'Oldest applied')], onChanged: (v) => setState(() => _appsSort = v)),
      ],
      _recentlyDeletedButton(labelled: false),
    ];

    final tabs = Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))), child: _statusTabs());

    if (!expanded) {
      return AppPage(
        title: 'Applications',
        subtitle: _summaryLine(),
        controller: _scrollController,
        actions: [_recentlyDeletedButton(labelled: false)],
        body: !hasApps || displayApps.isEmpty
            ? Padding(padding: const EdgeInsets.only(top: AppSpacing.xxl), child: emptyState)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tabs,
                  Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Row(children: [Expanded(child: _searchField()), const SizedBox(width: AppSpacing.sm), SortDropdown(height: 44, value: _appsSort, options: const [('newest', 'Newest applied'), ('oldest', 'Oldest applied')], onChanged: (v) => setState(() => _appsSort = v))])),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: AppGrid(
                      columns: 2,
                      gap: AppSpacing.md,
                      children: [for (final a in displayApps) _ApplicationCard(app: a, onRemove: () => _removeApplication(a), showBookmark: true, radius: AppRadius.xl)],
                    ),
                  ),
                ],
              ),
      );
    }

    final selected = displayApps.isEmpty ? null : displayApps.firstWhere((a) => a.id == _selectedId, orElse: () => displayApps.first);
    return Material(
      color: AppColors.white,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppBreakpoints.maxContentFor(context)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xl, gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(title: 'Applications', subtitle: _summaryLine(), actions: [for (var i = 0; i < controls.length; i++) ...[if (i > 0) const SizedBox(width: AppSpacing.sm), controls[i]]]),
                if (hasApps) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: tabs),
                Expanded(
                  child: !hasApps || selected == null
                      ? Center(child: emptyState)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 360,
                              child: ListView(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
                                children: [for (final a in displayApps) _masterRow(a, selected: a.id == selected.id)],
                              ),
                            ),
                            Container(width: 1, margin: const EdgeInsets.only(top: AppSpacing.md), color: AppColors.border),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: AppSpacing.lg),
                                child: ApplicationDetailView(key: ValueKey(selected.id), app: selected, user: context.watch<AppState>().user, onRemove: () => _removeApplication(selected)),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kept alive by StatefulShellRoute.indexedStack — without this, a job
    // applied-to from another tab (or restored from Recently Deleted)
    // wouldn't show here until a pull-to-refresh. Mirrors college_feed_screen.
    final appState = context.watch<AppState>();
    if (appState.dataVersion != _lastSeenDataVersion) {
      _lastSeenDataVersion = appState.dataVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

    // 2 columns at both tablet and desktop — 3 made ApplicationCard's
    // single-line title truncate hard and read as cramped; 2 matches the
    // reference mockup's own grid density and gives every card real room.
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = AppBreakpoints.isWide(context);
    final columns = width >= AppBreakpoints.medium ? 2 : 1;
    // Desktop's status/search/sort controls filter+reorder this; mobile/
    // tablet (no controls rendered) always get the untouched, unfiltered
    // _apps — same list as before this round.
    final displayApps = isTablet ? _visibleApps : _apps;
    if (isTablet) return _buildWide(context, displayApps);

    // A single scrollable (RefreshIndicator wrapping one ListView with the
    // header as its own leading items), not a fixed header Column sibling
    // above a separately-scrolling Expanded — a pinned header here left too
    // little of the fold visible, especially with the desktop-only stat
    // tiles/tabs stacked under it too.
    final headerItems = <Widget>[
            Padding(
              // isTablet adds AppSpacing.xl on top — sits directly under
              // TopNavBar's 64px bar with nothing else providing clearance.
              // Bottom tightened from md (16) — stacked with listContent's
              // own top padding right below, the two together read as too
              // much gap before the first card.
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm + (isTablet ? AppSpacing.xl : 0), AppSpacing.xl, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Applications', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                          child: Text(
                            '${_apps.length} active application${_apps.length != 1 ? 's' : ''}',
                            textAlign: TextAlign.left,
                            style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // A real, always-visible entry point — the swipe-delete
                  // undo snackbar covers the immediate "oops," but this is
                  // the actual backstop once that 4s toast is missed, and
                  // previously only existed on Profile, a different tab.
                  GestureDetector(
                    onTap: () => context.push('/applications/recently-deleted'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.sm),
                      child: Icon(Ionicons.trash_outline, size: 22, color: AppColors.gray400),
                    ),
                  ),
                ],
              ),
            ),
            // Desktop-only — 4 real stat tiles (bucketed from the actual
            // statuses below, never fabricated) + status tabs/search/sort.
            // Mobile/tablet render none of this; the header/list below are
            // otherwise completely unchanged for them.
            if (isTablet && _apps.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(child: StatTile(icon: Ionicons.document_text_outline, value: '${_apps.length}', label: 'Total applications')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        icon: Ionicons.trophy_outline,
                        iconColor: AppColors.successDark,
                        iconBg: AppColors.successA10,
                        value: '${_bucketFor('Offers').length}',
                        label: 'Offers',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        icon: Ionicons.time_outline,
                        iconColor: AppColors.warningDark,
                        iconBg: AppColors.warningA15,
                        value: '${_bucketFor('In Progress').length}',
                        label: 'In progress',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        icon: Ionicons.close_circle_outline,
                        iconColor: AppColors.gray500,
                        iconBg: AppColors.gray500A15,
                        value: '${_bucketFor('Not Selected').length}',
                        label: 'Not selected',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Expanded, not a bare Row child — CategoryTabBar's
                    // horizontal ListView needs a bounded width, which a
                    // plain (non-flex) Row child never gets.
                    Expanded(
                      child: CategoryTabBar(
                        tabs: [
                          CategoryTab(key: 'All', label: 'All', count: _apps.length),
                          CategoryTab(key: 'In Progress', label: 'In Progress', count: _bucketFor('In Progress').length),
                          CategoryTab(key: 'Offers', label: 'Offers', count: _bucketFor('Offers').length),
                          CategoryTab(key: 'Not Selected', label: 'Not Selected', count: _bucketFor('Not Selected').length),
                        ],
                        selected: _statusFilter,
                        onSelected: (key) => setState(() => _statusFilter = key),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 220,
                      child: PillInput(
                        controller: _searchController,
                        placeholder: 'Search your applications…',
                        icon: Ionicons.search_outline,
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SortDropdown(
                      value: _appsSort,
                      options: const [('newest', 'Newest applied'), ('oldest', 'Oldest applied')],
                      onChanged: (v) => setState(() => _appsSort = v),
                    ),
                  ],
                ),
              ),
            ],
            // Sits above the list itself, not inside its ListView — a
            // sibling in this outer Column so it stays pinned above both
            // the single-column and grid layouts below without needing to
            // be duplicated into each, and collapses to zero height once
            // shown (no permanently reserved space).
            const _SwipeHintBanner(),
    ];

    // Same 3-way branch as before (no apps at all / no apps match the
    // active filter / a real populated grid), just producing one block of
    // content instead of 3 separate inner ListViews — it's now the last
    // item of the single outer ListView below instead of RefreshIndicator's
    // own direct child, so the header above can scroll away with it.
    final Widget listContent;
    if (_apps.isEmpty) {
      listContent = Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, 0),
        child: EmptyState(
          icon: Ionicons.paper_plane_outline,
          title: 'No applications yet',
          subtitle: "Explore opportunities and apply — they'll show up here.",
          buttonLabel: 'Explore opportunities',
          onButtonTap: () => context.go('/tabs'),
        ),
      );
    } else if ((isTablet ? _visibleApps : _apps).isEmpty) {
      listContent = Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, 0),
        child: const EmptyState(
          icon: Ionicons.search_outline,
          title: 'No applications match',
          subtitle: 'Try a different search or clear the status filter.',
        ),
      );
    } else {
      listContent = Padding(
        // Top clearance — was 0, so the first card sat flush against the
        // "N active applications" subtitle above AND had its own top
        // shadow clipped (a plain ListView clips to its box regardless of
        // the Padding above it). lg (24) still comfortably exceeds
        // AppShadows.cardBuffer (16px) so the clip stays fixed; tightened
        // from xl (32) — combined with the header's own bottom padding
        // right above, the gap before the first card read as too much.
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
        child: Column(
          children: [
            if (columns == 1)
              ...displayApps.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ApplicationCard(app: entry.value, onRemove: () => _removeApplication(entry.value), showBookmark: isTablet),
                  ))
            else
              for (var row = 0; row < (displayApps.length / columns).ceil(); row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: row * columns + i < displayApps.length
                                ? _ApplicationCard(
                                    app: displayApps[row * columns + i],
                                    onRemove: () => _removeApplication(displayApps[row * columns + i]),
                                    showBookmark: isTablet,
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      // A single ListView, not a fixed header Column sibling above a
      // separately-scrolling Expanded — a pinned header here left too
      // little of the fold visible, especially with the desktop-only stat
      // tiles/tabs stacked under it too. RefreshIndicator now wraps this
      // one combined scrollable instead of just the list portion.
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : 720, child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: _onRefresh,
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [...headerItems, listContent],
          ),
        ),
      )),
    );
  }
}

/// One-time "swipe a card left to delete it" hint — this screen's cards use
/// a standard Dismissible, but nothing on-screen ever told a first-time
/// visitor that gesture exists. Auto-fades on its own timer rather than
/// needing a second swipe-to-dismiss gesture of its own — asking someone to
/// swipe away a hint *about* swiping is circular, and a timer guarantees it
/// clears even for someone who never touches the list at all. Shown once
/// per install via [applicationsSwipeHintShownPrefsKey], a SharedPreferences-
/// gated "seen once" flag.
class _SwipeHintBanner extends StatefulWidget {
  const _SwipeHintBanner();

  @override
  State<_SwipeHintBanner> createState() => _SwipeHintBannerState();
}

class _SwipeHintBannerState extends State<_SwipeHintBanner> {
  bool _visible = false;
  bool _faded = false;

  @override
  void initState() {
    super.initState();
    _maybeShow();
  }

  Future<void> _maybeShow() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(applicationsSwipeHintShownPrefsKey) ?? false) return;
    if (!mounted) return;
    setState(() => _visible = true);
    await prefs.setBool(applicationsSwipeHintShownPrefsKey, true);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _faded = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
      child: AnimatedOpacity(
        opacity: _faded ? 0 : 1,
        duration: Duration(milliseconds: _faded ? 400 : 300),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          // Plain white + a soft shadow, not a border — reads as a toast
          // floating just above the page rather than a call-to-action
          // chip. The earlier all-gray/offWhite version had no shadow or
          // border at all, so the pill's own shape barely registered
          // against this screen's plain white background; a real white
          // fill lifted off the page by AppShadows.soft (rather than a
          // color accent) gives it definition while keeping the simple
          // white-card/gray-text toast look.
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Ionicons.arrow_back_outline, size: 14, color: AppColors.gray500),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Swipe a card left to delete it',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One application card — extracted from the tracker's build method so it
/// can be reused per-cell in both the single-column list (phone) and the
/// 2-column grid (tablet) without duplicating the swipe-to-remove/tap
/// structure.
///
/// Naukri's own tracker card packs in more than a status pill: a recruiter
/// activity signal, a shortcut to similar roles, and inline "prep for this
/// interview" actions. A bare title/company/status card was leaving all of
/// that on the table, so this reuses the same shell but adds those rows —
/// every card, same format, regardless of status.
class _ApplicationCard extends StatelessWidget {
  final Application app;
  final VoidCallback onRemove;
  // Desktop-only addition (see the reference mockup) — reuses AppState's
  // existing saved-opportunity mechanism (the same one OpportunityRow/
  // OpportunityCarouselCard already use), just not previously wired into
  // this card. Off by default so mobile/tablet's card is byte-identical.
  final bool showBookmark;

  /// Corner radius of the card. The phone card is very round; the wide layouts use the same 20px as
  /// every other card.
  final double? radius;
  const _ApplicationCard({required this.app, required this.onRemove, this.showBookmark = false, this.radius});

  @override
  Widget build(BuildContext context) {
    final a = app;
    final opportunity = context.read<Repositories>().opportunities.getOpportunityById(a.opportunityId);
    final appState = showBookmark ? context.watch<AppState>() : null;
    final saved = appState?.isOpportunitySaved(a.opportunityId) ?? false;

    return Dismissible(
      key: ValueKey(a.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: const Icon(Ionicons.trash_outline, color: AppColors.white, size: 22),
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.md + AppSpacing.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius ?? AppRadius.md + AppSpacing.lg),
          onTap: () => context.push('/application/${a.id}'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            // Concentric with CompanyMark's own AppRadius.md corner sitting
            // AppSpacing.lg inside it, not an unrelated token.
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(radius ?? AppRadius.md + AppSpacing.lg),
              boxShadow: radius != null ? null : AppShadows.card,
              border: radius != null ? Border.all(color: AppColors.border) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CompanyMark(company: a.opportunity.company, size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.opportunity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(a.opportunity.company, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                          ),
                        ],
                      ),
                    ),
                    if (showBookmark)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.read<AppState>().toggleSavedOpportunity(a.opportunityId),
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Icon(saved ? Ionicons.bookmark : Ionicons.bookmark_outline, size: 18, color: saved ? AppColors.blue : AppColors.gray400),
                        ),
                      ),
                    const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      // Expanded + ellipsis, not a bare Text — "Better luck
                      // next time!" is long enough that on a narrow phone
                      // this date and the status badge could otherwise
                      // collide instead of one of them visibly giving way.
                      Expanded(
                        child: Text(
                          'Applied ${relativeTimeLabel(DateTime.tryParse(a.createdAt) ?? DateTime.now())}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(status: a.status),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                  // Three real tap targets, given actual chip weight (a
                  // bounded neutral pill) instead of bare icon+text — next
                  // to a tinted status badge, that neutral fill is what
                  // keeps "this is an action" visually distinct from "this
                  // is a status," instead of the two competing for the
                  // same visual weight. Replaces the old "Recruiter active"
                  // line (a decorative-only mock signal, not shown or
                  // linked anywhere else) and "Prep for this interview"
                  // caption (added a text row without adding information —
                  // Mock/Q&A are self-explanatory next to their icons).
                  //
                  // Mock/Prep are only relevant while an application is
                  // still live — a Rejected or Offer application has
                  // nothing left to interview-prep for, so those two are
                  // hidden once it's Rejected. Offer keeps them, though —
                  // unlike Rejected, an Offer here doesn't mean the
                  // student's done interviewing everywhere; Mock/Prep are
                  // still directly useful for their other, still-open
                  // applications. "Similar" stays for every status:
                  // discovering similar roles is relevant regardless of
                  // how this particular application ended.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _actionChip(
                              icon: Ionicons.copy_outline,
                              label: 'Similar',
                              onTap: () => context.push(Uri(
                                path: '/opportunities',
                                queryParameters: {'title': 'Similar roles', if (opportunity != null) 'category': opportunity.category},
                              ).toString()),
                            ),
                            if (a.status != 'Rejected') ...[
                              _actionChip(
                                icon: Ionicons.mic_outline,
                                label: 'Mock',
                                onTap: () => context.push('/booking?kind=placement'),
                              ),
                              _actionChip(
                                icon: Ionicons.book_outline,
                                label: 'Prep',
                                onTap: () => _showPrepSheet(
                                  context,
                                  prepCoursesForOpportunities(opportunity != null ? [opportunity] : const []),
                                  heading: 'Prep for this interview',
                                  subtitle: 'Aerostar Edge picks for the ${a.opportunity.title} role.',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Moved down here, away from the chevron in the header
                      // row above — sitting right next to that chevron made
                      // it too easy to mis-tap delete while reaching for
                      // "open this application." Bottom-right, with real
                      // separation from every other tap target on the card.
                      GestureDetector(
                        onTap: onRemove,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(Ionicons.trash_outline, size: 18, color: AppColors.gray400),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.blue),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.semibold)),
          ],
        ),
      ),
    );
  }
}

