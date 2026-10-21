import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../mockData/mock_courses.dart';
import '../../models/course.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_page.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/opportunity_detail_view.dart';
import '../../widgets/badges.dart';
import '../../widgets/company_mark.dart';
import '../../widgets/not_found_view.dart';
import '../../widgets/opportunity_meta.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/prep_course_card.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/app/opportunity/[id].tsx (OpportunityDetail).
class OpportunityDetailScreen extends StatefulWidget {
  final String id;
  const OpportunityDetailScreen({super.key, required this.id});

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  Opportunity? _opportunity;
  List<Course> _prepCourses = const [];
  List<Opportunity> _similarOpportunities = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<Repositories>().opportunities;
    final opp = repo.getOpportunityById(widget.id);
    if (opp == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final sameCategory = await repo.listOpportunities(categories: [opp.category]);
    if (!mounted) return;
    setState(() {
      _opportunity = opp;
      _prepCourses = prepCoursesFor(opp.prepCourses);
      _similarOpportunities = sameCategory.where((o) => o.id != opp.id).take(5).toList();
      _loading = false;
    });
  }

  bool get _applied => _opportunity != null && context.read<Repositories>().applications.isOpportunityApplied(_opportunity!.id);

  void _apply() {
    final o = _opportunity;
    if (o == null || _applied) return;
    startApplyFlow(context, o, onApplied: () => setState(() {}));
  }

  /// Tablet and desktop: the expanded window gets the role on the left and a pinned action card on
  /// the right; the medium window is one column with the Apply bar under it.
  Widget _buildWide(BuildContext context, Opportunity o, AppState appState) {
    final data = OpportunityDetailData(
      opportunity: o,
      prepCourses: _prepCourses,
      similar: _similarOpportunities,
      user: appState.user,
      applied: _applied,
      saved: appState.isOpportunitySaved(o.id),
      onApply: _apply,
      onToggleSave: () => appState.toggleSavedOpportunity(o.id),
      onAskExpert: () => context.push('/booking?kind=placement'),
      onOpenSimilar: (s) => context.push('/opportunity/${s.id}'),
      onOpenCourse: (c) => context.push('/course/${c.id}'),
      onViewAllSimilar: () => context.push(Uri(path: '/opportunities', queryParameters: {'title': o.category, 'category': o.category}).toString()),
    );
    if (AppBreakpoints.isExpanded(context)) {
      final columns = AppBreakpoints.gridColumns(context) >= 4 ? 3 : 3;
      return AppPage(
        backLabel: o.category,
        scroll: false,
        body: TwoPane(main: OpportunityDetailMain(data: data, similarColumns: columns), side: OpportunityDetailSideCard(data: data)),
      );
    }
    return Column(
      children: [
        Expanded(
          child: AppPage(
            backLabel: o.category,
            actions: [
              _circleAction(data.saved ? Ionicons.bookmark : Ionicons.bookmark_outline, data.saved ? 'Remove from saved' : 'Save', data.onToggleSave),
              _circleAction(Ionicons.chatbubble_outline, 'Ask an expert', data.onAskExpert),
            ],
            body: OpportunityDetailStacked(data: data),
          ),
        ),
        OpportunityApplyBar(data: data),
      ],
    );
  }

  Widget _circleAction(IconData icon, String label, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle), child: Icon(icon, size: 19, color: AppColors.blue)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final o = _opportunity;
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.white, body: Center(child: CircularProgressIndicator(color: AppColors.blue)));
    }
    if (o == null) {
      // null after loading means the id genuinely doesn't match anything —
      // a stale/invalid link — not "still loading."
      return const NotFoundView(
        title: 'Opportunity not found',
        message: "This opportunity may have been removed, or the link you followed is out of date.",
      );
    }

    final appState = context.watch<AppState>();
    if (AppBreakpoints.isWide(context)) return _buildWide(context, o, appState);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(bottom: AppSpacing.xxxl + AppSpacing.xxl + AppSpacing.sm + bottomInset),
              children: [
                // Naukri-style plain header — no hero photo. A small company
                // logo, title, and company name up top, everything else in
                // flat text rows instead of overlaid on an image.
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, 0),
                  child: Row(
                    children: [
                      BackChevron(color: AppColors.ink, fallbackRoute: '/tabs'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => appState.toggleSavedOpportunity(o.id),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                          child: Icon(
                            appState.isOpportunitySaved(o.id) ? Ionicons.bookmark : Ionicons.bookmark_outline,
                            size: 19,
                            color: appState.isOpportunitySaved(o.id) ? AppColors.blue : AppColors.gray500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => context.push('/booking?kind=placement'),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                          child: const Icon(Ionicons.chatbubble_outline, size: 18, color: AppColors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CompanyMark(company: o.company, size: 56),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 18px/600 — matches Internshala's measured
                            // detail-page hero title exactly.
                            //
                            // Hero tag must exactly match OpportunityRow's
                            // own 'opportunity-${o.id}' tag (see
                            // college_feed_screen.dart's _oppRow) — this is
                            // the only surface that currently pushes here
                            // with that tag set, so no collision risk from
                            // other entry points that don't set it.
                            Hero(
                              tag: 'opportunity-${o.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(o.title, style: AppTextStyles.h2.copyWith(color: AppColors.ink)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                              child: Text(o.company, style: AppTextStyles.bodyLg.copyWith(color: AppColors.blue, fontSize: 16, fontWeight: AppFontWeight.medium)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                  child: Row(
                    children: [
                      AppTag(label: o.type),
                      if (o.experience.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        AppTag(label: o.experience),
                      ],
                      if (o.demoOpening) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const AppTag(label: 'Demo opening'),
                      ],
                    ],
                  ),
                ),
                if (o.applicantCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Ionicons.people_outline, size: 14, color: AppColors.gray500),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${o.applicantCount} people applied', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                      ],
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetaRow(icon: Ionicons.location_outline, label: o.location),
                      if (o.sector.isNotEmpty) _MetaRow(icon: Ionicons.business_outline, label: o.sector),
                      // Internships show the monthly stipend and, under it, the
                      // LPA-equivalent range from the sheet; jobs show the range.
                      _MetaRow(icon: Ionicons.cash_outline, label: o.stipend),
                      if (o.internStipend != null && o.salaryRange.isNotEmpty) _MetaRow(icon: Ionicons.cash_outline, label: o.salaryRange),
                      _MetaRow(icon: Ionicons.time_outline, label: o.duration),
                      if (o.experience.isNotEmpty) _MetaRow(icon: Ionicons.briefcase_outline, label: 'Experience: ${o.experience}'),
                      if (o.department.isNotEmpty) _MetaRow(icon: Ionicons.layers_outline, label: o.department),
                      if (o.startupId.isNotEmpty) _MetaRow(icon: Ionicons.finger_print_outline, label: 'Startup ID: ${o.startupId}  ·  Job ID: ${o.id}'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About the role', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(noOrphan(o.about), style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, height: 18 / 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: Text('Requirements', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Column(
                          children: o.requirements
                              .map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                          child: const Icon(Ionicons.checkmark, size: 13, color: AppColors.blue),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(child: Text(r, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 12))),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // (The old "Work mode" block is gone: the job sheet has no
                      // work-mode column, and every job is a city-based role.)
                      if (_similarOpportunities.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Text('Similar roles', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                        ),
                        // A horizontal ListView clips to its exact SizedBox
                        // height, cutting AppShadows.card's blur off flat —
                        // see AppShadows.cardBuffer for the clearance this
                        // avoids. Bumped 176->216 for the 8pt spacing-grid
                        // pass — OpportunityRow's own internal AppSpacing
                        // paddings grew enough that 176 no longer fits it.
                        SizedBox(
                          height: 216 + AppShadows.cardBuffer * 2,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: AppShadows.cardBuffer),
                            scrollDirection: Axis.horizontal,
                            itemCount: _similarOpportunities.length,
                            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, i) {
                              final s = _similarOpportunities[i];
                              return SizedBox(
                                width: 260,
                                child: OpportunityRow(
                                  tag: s.type,
                                  title: s.title,
                                  subtitle: s.company,
                                  meta: [opportunityMeta(s)[0], s.stipend],
                                  deadlineLabel: s.deadlineLabel,
                                  deadlineUrgent: s.deadlineIsUrgent,
                                  // push, not pushReplacement — a
                                  // replacement silently discarded the
                                  // original opportunity from the back
                                  // stack, so back from the similar role
                                  // dropped the user wherever they were
                                  // before the original detail screen
                                  // instead of returning them to it.
                                  onTap: () => context.push('/opportunity/${s.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (_prepCourses.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Text('Prep for this role', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Column(
                            children: _prepCourses
                                .map((c) => PrepCourseCard(course: c, onTap: () => context.push('/course/${c.id}')))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
                decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
                // The bar itself spans the full (already 1224-capped) width
                // to read as a real footer, but the button inside is capped
                // — full: true (PillButton's own default) stretching to a
                // near-1200px CTA reads as a mammoth, not a call to action.
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                    child: PillButton(
                      label: _applied ? 'Applied' : 'Apply Now',
                      icon: _applied ? Ionicons.checkmark_circle : null,
                      onPressed: _apply,
                      disabled: _applied,
                    ),
                  ),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.blue),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium)),
        ],
      ),
    );
  }
}
