import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_articles.dart';
import '../../mockData/mock_bookings.dart';
import '../../mockData/mock_courses.dart';
import '../../mockData/mock_notifications.dart';
import '../../models/article.dart';
import '../../models/aptitude.dart';
import '../../models/booking.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../utils/recent_course_searches_prefs_key.dart';
import '../shared/notifications_screen.dart' show openNotifications;
import '../../widgets/app_chip.dart';
import '../../widgets/app_page.dart';
import '../../widgets/grid_cards.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/home_top_bar.dart';
import '../../widgets/badges.dart';
import '../../widgets/course_carousel_section.dart';
import '../../widgets/home_header.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _firstName(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  return trimmed.isEmpty ? 'there' : trimmed.split(' ').first;
}

/// Mirrors frontend/src/screens/SchoolHome.tsx (SchoolHome).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class SchoolHomeScreen extends StatefulWidget {
  const SchoolHomeScreen({super.key});

  @override
  State<SchoolHomeScreen> createState() => _SchoolHomeScreenState();
}

class _SchoolHomeScreenState extends State<SchoolHomeScreen> {
  List<Course> _courses = [];
  List<Article> _articles = [];
  List<Booking> _bookings = [];
  final _scrollController = ScrollController();
  int _lastSeenDataVersion = -1;
  // Consumed once, here, not read fresh in build() — see
  // college_feed_screen.dart's identical field for why.
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

  void _load() {
    final user = context.read<AppState>().user;
    final clusters = user?.aptitudeResults?.matches.map((m) => m.cluster).toList() ?? const <String>[];
    setState(() {
      _courses = recommendedCourses(clusters);
      _articles = mockArticles;
      _bookings = listBookings();
    });
  }

  Future<void> _onRefresh() async {
    _load();
  }

  String _prettyDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${_weekdayShort[d.weekday - 1]}, ${_monthShort[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }

  // Extracted from the old inline .map() builder so desktop can lay these
  // out as a grid (see _gridRows) without duplicating the card markup.
  Widget _articleCard(BuildContext context, Article a) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.sm),
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Full article — coming soon.')));
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          // Concentric with the inner ClipRRect: outerRadius = innerRadius (AppRadius.md) + the padding between them.
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.sm), boxShadow: AppShadows.soft),
          child: Row(
            children: [
              // Tinted icon, not a stock photo — same no-real-image rule as
              // every card in the app (see CompanyMark).
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Ionicons.document_text_outline, size: 32, color: AppColors.blue),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTag(label: a.tag),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(a.readTime, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
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

  // Top-aligned N-column grid (no IntrinsicHeight stretching — these cards
  // are near-uniform height already) — same shape as profile_screen.dart's
  // _pairedRows, generalized to any column count.
  List<Widget> _gridRows(List<Widget> cards, int columns) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += columns) {
      final rowItems = cards.skip(i).take(columns).toList();
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: c < rowItems.length ? rowItems[c] : const SizedBox()),
            ],
          ],
        ),
      ));
    }
    return rows;
  }

  // ---------------------------------------------------------------------------------------------
  // Tablet and desktop layout. The phone layout in build() below is unchanged.
  // ---------------------------------------------------------------------------------------------

  Widget _wideArticleCard(Article a) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Full article — coming soon.')));
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A tinted icon block, not a stock photo: the same no-real-image rule as every other card.
              Container(height: 112, color: AppColors.offWhite, alignment: Alignment.center, child: const Icon(Ionicons.document_text_outline, size: 32, color: AppColors.ink)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a.tag} · ${a.readTime}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold, height: 1.3)),
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

  Widget _wideCounselingCard({required Booking? upcoming, required bool compact}) {
    if (upcoming != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/tabs/sessions'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book free counseling', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('Talk 1:1 with an expert about your path.', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  // A white pill (not yellow on yellow), so the button reads on the yellow card.
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.push('/booking?kind=counseling'),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Text('Book a session', style: AppTextStyles.bodyLg.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.semibold))]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(Ionicons.chatbubbles, size: compact ? 40 : 56, color: AppColors.blue),
        ],
      ),
    );
  }

  Widget _wideClustersCard(List<AptitudeMatch> matches, {required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md + 4 : AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Your career clusters', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: compact ? 14 : 16))),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/school/aptitude-intro'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(compact ? 'Retake' : 'Retake test', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                  ),
                ),
              ),
            ],
          ),
          for (var i = 0; i < matches.length && i < 3; i++)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(Uri(path: '/school/results', queryParameters: {'cluster': matches[i].cluster}).toString()),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(width: 28, height: 28, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle), child: Text('${i + 1}', style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.semibold))),
                      const SizedBox(width: AppSpacing.md - 4),
                      Expanded(child: Text(matches[i].cluster, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium))),
                      if (!compact) Text('${matches[i].matchPercent}%', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wideAptitudeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APTITUDE TEST', style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('Find what fits you', style: AppTextStyles.h3.copyWith(color: AppColors.ink))),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('12 quick questions to unlock personalized clusters and recommendations.', style: AppTextStyles.body.copyWith(color: AppColors.gray500))),
          const Spacer(),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: PillButton(label: 'Take the aptitude test', icon: Ionicons.flash, onPressed: () => context.push('/school/aptitude-intro'))),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context, AppState appState, User? user, {required Booking? upcoming, required bool showAptitudeCta}) {
    final expanded = AppBreakpoints.isExpanded(context);
    final compact = !expanded;
    final gap = expanded ? AppSpacing.lg : AppSpacing.md;
    final columns = AppBreakpoints.gridColumns(context);
    final gutter = AppBreakpoints.gutter(context);
    final unread = appState.hasUnreadNotifications(mockSchoolNotifications.map((n) => n.id).toList());
    final matches = user?.aptitudeResults?.matches ?? const <AptitudeMatch>[];

    final searchField = HomeSearchBar(
      height: expanded ? 44 : 54,
      hint: 'Search courses',
      compactHint: 'Search courses',
      recentKey: recentCourseSearchesPrefsKey,
      termsBuilder: courseSearchSuggestionTerms,
      routeFor: (q) => '/courses/search?q=${Uri.encodeQueryComponent(q)}',
    );

    final courseCards = _courses.take(expanded ? columns : 4).toList();
    final articleColumns = expanded ? (columns >= 4 ? 4 : 3) : 2;
    final articleCards = _articles.take(expanded ? articleColumns : 2).toList();

    final heroRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: expanded ? 3 : 1, child: _wideCounselingCard(upcoming: upcoming, compact: compact)),
        SizedBox(width: gap),
        Expanded(flex: expanded ? 2 : 1, child: showAptitudeCta ? _wideAptitudeCard() : _wideClustersCard(matches, compact: compact)),
      ],
    );

    return Material(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expanded)
            HomeTopBar(
              search: searchField,
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
                        Text(_justOnboarded ? 'Welcome, ${_firstName(user?.name)}' : 'Welcome back', style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                        Text(user?.name ?? 'Student', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                        if (!expanded) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: searchField),
                        const SizedBox(height: AppSpacing.lg),
                        IntrinsicHeight(child: heroRow),
                        SectionHeading(title: 'Recommended for you', padding: const EdgeInsets.only(top: AppSpacing.xxl - 8, bottom: AppSpacing.md), onViewAll: () => context.go('/tabs/explore')),
                        AppGrid(columns: columns, gap: gap, children: [for (final c in courseCards) CourseGridCard(course: c, showModules: false, onTap: () => context.push('/course/${c.id}'))]),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl - 8, bottom: AppSpacing.md),
                          child: Text('Resources for you', style: AppTextStyles.h3.copyWith(color: AppColors.ink)),
                        ),
                        AppGrid(columns: articleColumns, gap: gap, children: [for (final a in articleCards) _wideArticleCard(a)]),
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
    final appState = context.watch<AppState>();
    final user = appState.user;
    final clusters = user?.aptitudeResults?.matches.map((m) => m.cluster).toList() ?? const <String>[];
    final showAptitudeCta = user?.aptitudeResults == null;
    // _bookings is sorted ascending by real date/time, but nothing
    // previously excluded a session whose date had already passed — a
    // lapsed booking could sit in this "upcoming" slot indefinitely,
    // still showing its confirmed checkmark and Reschedule/Cancel actions.
    final now = DateTime.now();
    final upcoming = _bookings.cast<Booking?>().firstWhere(
          (b) {
            final dt = parseBookingDateTime(b!.date, b.time);
            return dt == null || dt.isAfter(now);
          },
          orElse: () => null,
        );
    // A booking made/cancelled on the Sessions tab (kept alive in the
    // background) otherwise wouldn't update this card until a manual
    // pull-to-refresh — see sessions_screen.dart's identical pattern.
    if (appState.dataVersion != _lastSeenDataVersion) {
      _lastSeenDataVersion = appState.dataVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final isTablet = AppBreakpoints.isWide(context);
    if (isTablet) return _buildWide(context, appState, user, upcoming: upcoming, showAptitudeCta: showAptitudeCta);

    return Scaffold(
      backgroundColor: AppColors.white,
      // Bug fix, not just desktop polish — this screen had NO ResponsiveBody
      // at all before, so content stretched fully unbounded past 520px at
      // any width >=600, tablet included.
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            HomeHeader(
              name: user?.name,
              photoUrl: user?.photoUrl,
              // See college_feed_screen.dart's identical branch — a
              // brand-new arrival gets a one-time personalized welcome.
              subtitle: _justOnboarded ? 'Welcome, ${_firstName(user?.name)}' : 'Your career journey',
              onAvatarTap: () => context.go('/tabs/profile'),
              onBellTap: () => openNotifications(context),
              unread: appState.hasUnreadNotifications(
                mockSchoolNotifications.map((n) => n.id).toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: _onRefresh,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    if (upcoming != null)
                      GestureDetector(
                        onTap: () => context.go('/tabs/sessions'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                      )
                    else
                      GestureDetector(
                        onTap: () => context.push('/booking?kind=counseling'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Book free counseling', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 18, fontWeight: AppFontWeight.bold)),
                                    Padding(
                                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                                      child: Text(noOrphan('Talk 1:1 with an expert about your path.'), style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Ionicons.arrow_forward_circle, size: 34, color: AppColors.yellow),
                            ],
                          ),
                        ),
                      ),
                    if (showAptitudeCta)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'APTITUDE TEST',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.blue,
                                  fontWeight: AppFontWeight.medium,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
                                child: Text(
                                  'Find what fits you',
                                  textAlign: TextAlign.left,
                                  style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(
                                  noOrphan('12 quick questions to unlock personalized clusters and recommendations.'),
                                  textAlign: TextAlign.left,
                                  style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.lg),
                                child: PillButton(
                                  label: 'Take the aptitude test',
                                  icon: Ionicons.flash,
                                  onPressed: () => context.push('/school/aptitude-intro'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (clusters.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl, left: AppSpacing.xl, right: AppSpacing.xl),
                        child: Row(
                          children: [
                            Expanded(child: Text('Your career clusters', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold))),
                            // The only other way back to the test once it's
                            // complete is a link buried inside Results —
                            // without this, the aptitude CTA card just
                            // vanishes for good after the first attempt.
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.push('/school/aptitude-intro'),
                              // Padding inside the tap target, not just
                              // text sized to its own line — was well
                              // under the ~40-44px minimum this app
                              // otherwise aims for.
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                                child: Text('Retake test', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 44 + AppSpacing.sm,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.md),
                          scrollDirection: Axis.horizontal,
                          itemCount: clusters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) => Align(
                            alignment: Alignment.center,
                            // Each chip jumps straight to its own cluster's
                            // card on Results, not just the generic top
                            // match — previously every chip opened the
                            // identical screen regardless of which cluster
                            // was tapped.
                            child: AppChip(
                              label: clusters[i],
                              onPressed: () => context.push(Uri(path: '/school/results', queryParameters: {'cluster': clusters[i]}).toString()),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // No manual top gap — CarouselSectionHeading already
                    // supplies a divider + AppSpacing.xl clearance above it.
                    CourseCarouselSection(title: 'Recommended for you', courses: _courses, onViewAll: () => context.go('/tabs/explore')),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl, left: AppSpacing.xl, right: AppSpacing.xl),
                      child: Text('Resources for you', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                      // Desktop: a real 3-column grid (top-aligned, same
                      // "Card/Block Layout" pairing as profile_screen.dart's
                      // _pairedRows — these cards are near-uniform height so
                      // no IntrinsicHeight stretching is needed). Mobile/
                      // tablet: the original single stacked column,
                      // unchanged.
                      child: Column(
                        children: isTablet
                            ? _gridRows([for (final a in _articles) _articleCard(context, a)], 3)
                            : [for (final a in _articles) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _articleCard(context, a))],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
