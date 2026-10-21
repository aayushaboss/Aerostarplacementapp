import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_courses.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/group_by_category.dart';
import '../../utils/recent_course_searches_prefs_key.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_page.dart';
import '../../widgets/auto_carousel.dart';
import '../../widgets/grid_cards.dart';
import '../../widgets/home_top_bar.dart';
import '../../widgets/side_sheet.dart';
import '../../widgets/sort_dropdown.dart';
import '../../widgets/category_tab_bar.dart';
import '../../widgets/content_card.dart';
import '../../widgets/course_carousel_section.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/responsive_body.dart';
import 'course_filter_screen.dart';

// Shown in place of Recent searches until the browser has any history, so the
// suggestion area is never empty. Every term matches a real course title or
// category (the search matches either), so a tap always lands on results.
const _popularSearches = ['Marketing', 'AI', 'Sales', 'Finance', 'Operations', 'Design'];

// aptitudeResults (the real source for "Recommended for you") is only ever
// populated via the school-only /school/aptitude flow — for college this
// carousel was silently dead every time, since `clusters` was always
// empty. College has no aptitude test, but it does have `user.roles`
// (interested-roles, set at onboarding) — mapped here to the nearest
// course cluster so college gets an equivalent, if coarser, signal
// instead of just never seeing this section.
const _roleToClusterFallback = {
  'Marketing': 'Design & Creative',
  'Social Media Marketing': 'Design & Creative',
  'Graphic Designing': 'Design & Creative',
  'Sales & Business Development': 'Humanities & Law',
  'Human Resource': 'Humanities & Law',
  'Operations': 'Commerce & Finance',
  'Finance & Accounting': 'Commerce & Finance',
};

/// Mirrors frontend/src/screens/CoursesExplore.tsx (CoursesExplore).
/// School user's "Explore" tab — also the college "Courses" tab.
///
/// Naukri-style browse-by-topic, matching how the Home feed's job listings
/// are organized: one horizontally-scrolling carousel per category instead
/// of a single flat list gated behind a category-filter chip row. A typed
/// search still collapses to a flat ranked list, same as everywhere else a
/// search box sits above sectioned content.
class CoursesExploreScreen extends StatefulWidget {
  const CoursesExploreScreen({super.key});

  @override
  State<CoursesExploreScreen> createState() => _CoursesExploreScreenState();
}

class _CoursesExploreScreenState extends State<CoursesExploreScreen> {
  final _scrollController = ScrollController();
  // This screen is mounted at branch 1 for school (Browse tab) and branch 3
  // for college (Courses tab) — see BrowseTabScreen/TabsScaffold, which pick
  // the same branch index the same way. Remembered so dispose() unregisters
  // the exact branch this instance registered, not whichever segment the
  // user happens to be on by the time dispose runs.
  int? _registeredBranchIndex;

  CourseFilterSelection _filter = const CourseFilterSelection();
  // Desktop-only tabs+grid state (see _desktopCourseTabsGrid) — mobile/
  // tablet never read this, so it can't affect the carousel-stack view.
  String? _selectedCourseTab;

  Future<void> _openFilter() async {
    final result = await context.push<CourseFilterSelection>('/school/course-filter', extra: _filter);
    if (result != null) setState(() => _filter = result);
  }

  @override
  void initState() {
    super.initState();
    final isSchool = context.read<AppState>().user?.segment == Segment.school;
    _registeredBranchIndex = isSchool ? 1 : 3;
    ScrollToTopRegistry.register(_registeredBranchIndex!, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    if (_registeredBranchIndex != null) ScrollToTopRegistry.unregister(_registeredBranchIndex!);
    _scrollController.dispose();
    super.dispose();
  }

  // The title, credibility carousel, and search+filter row used to be
  // fixed siblings above the results — outside any scrollable, they never
  // moved no matter how far the results below were scrolled. Folded into
  // the same ListView as the results instead (as leading items), mirroring
  // how college_feed_screen.dart/school_home_screen.dart already solved
  // this identical problem: "they're just the first few items of the one
  // scrollable list, so they scroll away with everything else." No new
  // scroll-direction-tracking code needed — scrolling back up naturally
  // brings them back the same way it brings back any earlier list content.
  // Pinned above the scrolling content (like Home): the title plus the same
  // suggest-as-you-type search bar the Home feed uses, and the filter button.
  // Typing never filters the page behind it: you pick a suggestion or press the
  // tick, and the results open on their own screen (/courses/search).
  Widget _pinnedHeader(double topInset, bool isFiltering, bool isTablet) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // isTablet adds AppSpacing.xl on top — sits directly under
            // TopNavBar's 64px bar with nothing else providing clearance.
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm + (isTablet ? AppSpacing.xl : 0), AppSpacing.xl, 0),
            child: Text('Courses', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: HomeSearchBar(
                    hint: 'Search courses',
                    compactHint: 'Search courses',
                    recentKey: recentCourseSearchesPrefsKey,
                    termsBuilder: courseSearchSuggestionTerms,
                    starters: _popularSearches,
                    routeFor: (q) => '/courses/search?q=${Uri.encodeQueryComponent(q)}',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _openFilter,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      // Plain circle, no border, offWhite fill in both states —
                      // matches every other standalone icon-only button in the
                      // app (header search/bell, the opportunity-detail
                      // bookmark/chat buttons). "Active" is signaled the same
                      // way the bookmark button does it — swap to the filled
                      // glyph + ink tint — rather than inverting the whole
                      // button's fill, which no other icon button here does.
                      decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                      child: Icon(
                        isFiltering ? Ionicons.options : Ionicons.options_outline,
                        size: 20,
                        color: isFiltering ? AppColors.blue : AppColors.ink,
                      ),
                    ),
                    // Same permanent brand dot as Home's filter icon — a
                    // standing reminder that Courses is scoped to the
                    // user's own picks, not a one-time nudge. (11, 12), not
                    // Home's (9, 10): this button is 44px, not 40px — see
                    // home_header.dart's own note that (11, 12) was this
                    // exact ratio's value before that icon shrank to 40px.
                    Positioned(
                      top: 11,
                      right: 12,
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
              ],
            ),
          ),
        ],
      );

  List<Widget> _headerItems(bool isSchool) => [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AutoCarousel(
            // Same size and cadence as Home's promo cards (college_feed_screen.dart)
            // so these trust cards read as part of the same family.
            height: 112,
            interval: const Duration(seconds: 8),
            // "NEP 2020" (the National Education Policy) reads as K-12
            // curriculum framing — fine for a school-stage audience, but
            // this screen is shared with college/placement-stage students
            // who saw the exact same badge unchanged. College gets a
            // placement-relevant equivalent instead.
            cards: isSchool
                ? const [
                    _CredibilityCard(
                      icon: Ionicons.school,
                      title: 'NEP 2020 Aligned',
                      caption: 'Courses mapped to the National Education Policy 2020.',
                    ),
                    _CredibilityCard(
                      icon: Ionicons.ribbon,
                      title: 'Skill India Certified',
                      caption: "Content aligned with Skill India's competency framework.",
                    ),
                    _CredibilityCard(
                      icon: Ionicons.shield_checkmark,
                      title: 'NSDC Approved',
                      caption: 'Backed by the National Skill Development Corporation.',
                    ),
                  ]
                : const [
                    _CredibilityCard(
                      icon: Ionicons.ribbon,
                      title: 'Industry-recognized certification',
                      caption: 'Certificates recruiters actually look for.',
                    ),
                    _CredibilityCard(
                      icon: Ionicons.shield_checkmark,
                      title: 'Skill India Certified',
                      caption: "Content aligned with Skill India's competency framework.",
                    ),
                    _CredibilityCard(
                      icon: Ionicons.briefcase,
                      title: 'Built for placement season',
                      caption: 'Interview, resume, and aptitude prep included.',
                    ),
                  ],
          ),
        ),
      ];

  Widget _resultCard(Course c) {
    return ContentCard(
      icon: categoryIcons[c.category],
      tag: c.category,
      title: c.title,
      meta: [c.duration, '${c.modules} modules'],
      linkLabel: 'View syllabus',
      onTap: () => context.push('/course/${c.id}'),
    );
  }

  // 1-column or 2-column-at-tablet-width rendering for one list of cards —
  // shared between the flat (ungrouped) case and each category group below,
  // so both lay out identically.
  List<Widget> _cardsFor(List<Course> items, int columns) {
    if (columns == 1) {
      return items.map((c) => Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg), child: _resultCard(c))).toList();
    }
    return [
      for (var row = 0; row < (items.length / columns).ceil(); row++)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: row * columns + i < items.length ? _resultCard(items[row * columns + i]) : const SizedBox()),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  Widget _categoryHeading(String category, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
      child: Text('$category ($count)', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 16)),
    );
  }

  // Groups by category (in the exact order the categories were selected in
  // the filter, matching what the picker itself shows) whenever more than
  // one is active — an active multi-category filter is exactly the case
  // that used to interleave, e.g., Technology/Design/Science cards with no
  // way to browse just one category's cards in one continuous run. A single
  // category, or none, renders flat as before — a one-item group heading
  // would be redundant noise.
  List<Widget> _resultWidgets(List<Course> results, int columns) {
    if (_filter.categories.length > 1) {
      final grouped = groupByCategory<Course>(results, (c) => c.category, order: _filter.categories);
      return [
        for (final entry in grouped.entries) ...[
          _categoryHeading(entry.key, entry.value.length),
          ..._cardsFor(entry.value, columns),
        ],
      ];
    }
    return _cardsFor(results, columns);
  }

  // Desktop-only replacement for the carousel-per-category stack below —
  // same real category list + real per-category counts (filterCourses is
  // the exact function each carousel already used), just tabs + one shared
  // grid instead of separate horizontal lanes. Mobile/tablet never call
  // this — the carousel stack is completely unchanged for them.
  Widget _desktopCourseTabsGrid(BuildContext context, List<Course> recommended) {
    final topics = <(String key, String label, List<Course> items)>[
      if (recommended.isNotEmpty) ('recommended', 'Recommended for you', recommended),
      for (final category in courseCategories) (category, category, filterCourses(category)),
    ].where((t) => t.$3.isNotEmpty).toList();
    if (topics.isEmpty) return const SizedBox.shrink();
    final selectedKey = topics.any((t) => t.$1 == _selectedCourseTab) ? _selectedCourseTab! : topics.first.$1;
    final selected = topics.firstWhere((t) => t.$1 == selectedKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
          child: CategoryTabBar(
            tabs: [for (final t in topics) CategoryTab(key: t.$1, label: t.$2, count: t.$3.length)],
            selected: selectedKey,
            onSelected: (key) => setState(() => _selectedCourseTab = key),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          // 2 columns — matches Applications' own card grid, per direct
          // feedback that its layout should be the reference for this one
          // too, now that ContentCard's title truncates at 1 line the same
          // way _ApplicationCard's does instead of wrapping awkwardly.
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _cardsFor(selected.$3, 2)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------------------------
  // Tablet and desktop layout. The phone layout in build() below is unchanged.
  // ---------------------------------------------------------------------------------------------

  String _courseSort = 'recommended';

  List<String> _trustLines(bool isSchool) => isSchool ? const ['NEP 2020 Aligned', 'Skill India Certified', 'NSDC Approved'] : const ['Industry-recognized certification', 'Skill India Certified', 'Built for placement season'];

  Widget _trustRow(bool isSchool) => Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          for (final t in _trustLines(isSchool))
            Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.shield_checkmark_outline, size: 14, color: AppColors.ink), const SizedBox(width: 6), Text(t, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))]),
        ],
      );

  Widget _courseFilterFields(CourseFilterSelection value, ValueChanged<CourseFilterSelection> onChanged) {
    final labelStyle = AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md - 4), child: Text('Duration', style: labelStyle)),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final b in courseDurationBuckets)
              AppChip(
                label: b,
                dense: true,
                selected: value.durationBuckets.contains(b),
                onPressed: () => onChanged(CourseFilterSelection(categories: value.categories, durationBuckets: value.durationBuckets.contains(b) ? value.durationBuckets.where((x) => x != b).toList() : [...value.durationBuckets, b])),
              ),
          ],
        ),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.lg - 4, bottom: AppSpacing.md - 4), child: Text('Categories', style: labelStyle)),
        for (final c in courseCategories)
          FilterCheckRow(
            label: c,
            checked: value.categories.contains(c),
            onTap: () => onChanged(CourseFilterSelection(categories: value.categories.contains(c) ? value.categories.where((x) => x != c).toList() : [...value.categories, c], durationBuckets: value.durationBuckets)),
          ),
      ],
    );
  }

  Future<void> _openFilterSheet() async {
    var draft = _filter;
    await showSideSheet(
      context: context,
      title: 'Filter courses',
      content: (context, setSheet) => _courseFilterFields(draft, (v) => setSheet(() => draft = v)),
      onReset: (setSheet) => setSheet(() => draft = const CourseFilterSelection()),
      onApply: () => setState(() => _filter = draft),
    );
  }

  List<Course> _sortedCourses(List<Course> items) {
    final out = List<Course>.of(items);
    if (_courseSort == 'shortest') out.sort((a, b) => a.months.compareTo(b.months));
    if (_courseSort == 'longest') out.sort((a, b) => b.months.compareTo(a.months));
    return out;
  }

  Widget _buildWide(BuildContext context, User? user, bool isSchool, List<Course> recommended) {
    final columns = AppBreakpoints.gridColumns(context).clamp(2, 4);

    final topics = <(String key, String label, List<Course> items)>[
      if (recommended.isNotEmpty) ('recommended', 'Recommended for you', recommended),
      for (final category in courseCategories) (category, category, filterCourses(category)),
    ].where((t) => t.$3.isNotEmpty).toList();
    final selectedKey = topics.any((t) => t.$1 == _selectedCourseTab) ? _selectedCourseTab! : (topics.isEmpty ? '' : topics.first.$1);
    final selectedItems = topics.isEmpty ? const <Course>[] : topics.firstWhere((t) => t.$1 == selectedKey).$3;
    final duration = _filter.durationBuckets.isEmpty ? 'any' : _filter.durationBuckets.first;
    var shown = selectedItems;
    if (duration != 'any') {
      final allowed = filterCoursesAdvanced(categories: const [], durationBuckets: [duration]).map((c) => c.id).toSet();
      shown = selectedItems.where((c) => allowed.contains(c.id)).toList();
    }
    shown = _sortedCourses(shown);

    final searchBar = HomeSearchBar(
      height: 44,
      hint: 'Search courses, skills',
      compactHint: 'Search courses',
      recentKey: recentCourseSearchesPrefsKey,
      termsBuilder: courseSearchSuggestionTerms,
      starters: _popularSearches,
      routeFor: (q) => '/courses/search?q=${Uri.encodeQueryComponent(q)}',
    );

    // One quiet toolbar instead of tabs plus a filter column: pick a category, a length and a sort order.
    final countLabel = Text('${shown.length} ${shown.length == 1 ? 'course' : 'courses'}', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium));
    final toolbar = Row(
      children: [
        SortDropdown(prefix: 'Category: ', value: selectedKey, options: [for (final t in topics) (t.$1, '${t.$2} (${t.$3.length})')], onChanged: (k) => setState(() => _selectedCourseTab = k)),
        const SizedBox(width: AppSpacing.sm),
        SortDropdown(
          prefix: 'Length: ',
          value: duration,
          options: [('any', 'Any'), for (final b in courseDurationBuckets) (b, b)],
          onChanged: (v) => setState(() => _filter = CourseFilterSelection(categories: _filter.categories, durationBuckets: v == 'any' ? const [] : [v])),
        ),
        const Spacer(),
        Padding(padding: const EdgeInsets.only(right: AppSpacing.md), child: countLabel),
        SortDropdown(value: _courseSort, options: const [('recommended', 'Recommended'), ('shortest', 'Shortest first'), ('longest', 'Longest first')], onChanged: (v) => setState(() => _courseSort = v)),
      ],
    );

    return AppPage(
      title: 'Courses',
      subtitle: _trustLines(isSchool).take(2).join('  ·  '),
      controller: _scrollController,
      actions: [SizedBox(width: 340, child: searchBar)],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBreakpoints.isExpanded(context)
              ? toolbar
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SortDropdown(prefix: 'Category: ', value: selectedKey, options: [for (final t in topics) (t.$1, '${t.$2} (${t.$3.length})')], onChanged: (k) => setState(() => _selectedCourseTab = k)),
                    SortDropdown(prefix: 'Length: ', value: duration, options: [('any', 'Any'), for (final b in courseDurationBuckets) (b, b)], onChanged: (v) => setState(() => _filter = CourseFilterSelection(categories: _filter.categories, durationBuckets: v == 'any' ? const [] : [v]))),
                    SortDropdown(value: _courseSort, options: const [('recommended', 'Recommended'), ('shortest', 'Shortest first'), ('longest', 'Longest first')], onChanged: (v) => setState(() => _courseSort = v)),
                    countLabel,
                  ],
                ),
          const SizedBox(height: AppSpacing.lg),
          if (shown.isEmpty)
            const Padding(padding: EdgeInsets.only(top: AppSpacing.xxl), child: EmptyState(icon: Ionicons.search_outline, title: 'No courses found', subtitle: 'No courses match these filters.'))
          else
            AppGrid(columns: columns, gap: AppSpacing.md, children: [for (final c in shown) CourseGridCard(course: c, showCategory: selectedKey == 'recommended', onTap: () => context.push('/course/${c.id}'))]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final user = context.watch<AppState>().user;
    final isSchool = user?.segment == Segment.school;
    final aptitudeClusters = user?.aptitudeResults?.matches.map((m) => m.cluster).toList() ?? const <String>[];
    // College fallback — see _roleToClusterFallback's own comment.
    final roleClusters = (user?.roles ?? const <String>[]).map((r) => _roleToClusterFallback[r]).whereType<String>().toSet().toList();
    final clusters = aptitudeClusters.isNotEmpty ? aptitudeClusters : roleClusters;
    final recommended = clusters.isNotEmpty ? recommendedCourses(clusters) : const <Course>[];

    if (AppBreakpoints.isWide(context)) return _buildWide(context, user, isSchool, recommended);

    final isFiltering = !_filter.isEmpty;
    // Search and the active filter now combine (AND) instead of being
    // mutually exclusive modes — filterCoursesAdvanced already supports a
    // query alongside its facets (Round V), so both narrow the same result
    // set together.
    final hasQuery = isFiltering;
    final results = hasQuery
        ? filterCoursesAdvanced(categories: _filter.categories, durationBuckets: _filter.durationBuckets)
        : const <Course>[];
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = AppBreakpoints.isWide(context);
    // 2 at desktop — matches Applications' own card grid (see
    // _desktopCourseTabsGrid's identical comment above).
    final columns = width >= AppBreakpoints.medium ? 2 : (width >= AppBreakpoints.medium ? 2 : 1);

    String emptyMessage() => 'No courses match these filters.';

    // Every state below renders as exactly one ListView — the previous
    // isFiltering branch used to nest a second, independently-scrolling
    // ListView inside a fixed "N courses found" row; that's flattened here
    // too, so there's never more than one scrollable region on this screen.
    late final List<Widget> bodyItems;
    if (hasQuery) {
      bodyItems = [
        ..._headerItems(isSchool),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${results.length} ${results.length == 1 ? 'course' : 'courses'} found',
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                ),
              ),
              if (isFiltering)
                GestureDetector(
                  onTap: () => setState(() => _filter = const CourseFilterSelection()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                    child: Text('Clear filters', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                  ),
                ),
            ],
          ),
        ),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(top: AppSpacing.xxxl),
            child: EmptyState(icon: Ionicons.search_outline, title: 'No courses found', subtitle: emptyMessage()),
          )
        else
          ..._resultWidgets(results, columns),
      ];
    } else {
      if (isTablet) {
        bodyItems = [
          ..._headerItems(isSchool),
          // Desktop-only: category tabs + one shared grid, replacing the
          // carousel-per-category stack below. Mobile/tablet never reach
          // this branch.
          _desktopCourseTabsGrid(context, recommended),
        ];
      } else {
        final carousels = [
          if (recommended.isNotEmpty) CourseCarouselSection(title: 'Recommended for you', courses: recommended),
          for (final category in courseCategories) CourseCarouselSection(
            title: category,
            courses: filterCourses(category),
            visibleCap: 12,
            onViewAll: () => context.push('/courses/search?category=${Uri.encodeQueryComponent(category)}'),
          ),
        ];
        bodyItems = [
          ..._headerItems(isSchool),
          // No manual inter-carousel gap needed — CarouselSectionHeading
          // already supplies a divider + AppSpacing.xl clearance above each
          // one, including the first.
          ...carousels,
        ];
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        maxWidth: isTablet ? 1224 : (hasQuery ? 720 : AppBreakpoints.maxContentWidth),
        child: Column(
          children: [
            _pinnedHeader(topInset, isFiltering, isTablet),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                children: bodyItems,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// One trust-badge card in the credibility carousel above the search bar.
/// Deliberately the same design as Home's promo cards ("Get recruiters to
/// notice you"): solid brand fill, bold ink title, softer ink caption, and a
/// large filled glyph on the right. Not tappable — a claim like "NEP 2020
/// Aligned" has nowhere to navigate.
class _CredibilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  const _CredibilityCard({required this.icon, required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md - 4),
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
                  noOrphan(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 16, fontWeight: AppFontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    noOrphan(caption),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 32, color: AppColors.yellow),
        ],
      ),
    );
  }
}

