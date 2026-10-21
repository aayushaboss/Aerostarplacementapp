import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../mockData/mock_courses.dart';
import '../../models/course.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_page.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/badges.dart';
import '../../widgets/company_mark.dart';
import '../../widgets/not_found_view.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/app/course/[id].tsx (CourseDetail).
/// Laid out to match OpportunityDetailScreen's structure — plain header
/// (no hero photo), title/subtitle row, tag chips, a meta-row block, then
/// flat text sections — so course and job detail pages read as the same
/// design language instead of two different ones.
class CourseDetailScreen extends StatefulWidget {
  final String id;
  const CourseDetailScreen({super.key, required this.id});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  List<SyllabusModule> _syllabus = const [];

  @override
  void initState() {
    super.initState();
    // TODO: replace with real API call
    final course = getCourseById(widget.id);
    if (course != null) {
      _course = course;
      _syllabus = courseSyllabus(course);
    }
  }

  /// Tablet and desktop: tags, title, about and syllabus on the left and a pinned card with the
  /// course facts and "Talk to a counselor" on the right (one column with a bar under it on a
  /// medium window).
  Widget _buildWide(BuildContext context, Course c) {
    final expanded = AppBreakpoints.isExpanded(context);
    Widget metaRow(IconData icon, String label) => Row(children: [Icon(icon, size: 16, color: AppColors.gray500), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium)))]);
    final facts = <Widget>[
      metaRow(Ionicons.time_outline, c.duration),
      if (c.months > 0) metaRow(Ionicons.calendar_outline, 'About ${c.months == c.months.roundToDouble() ? c.months.round() : c.months} months'),
      metaRow(Ionicons.albums_outline, '${c.modules} modules'),
      metaRow(Ionicons.ribbon_outline, 'Certificate on completion'),
      metaRow(Ionicons.layers_outline, c.category),
    ];

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [AppTag(label: c.category), const AppTag(label: 'Certificate included')]),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Text(c.title, style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 26))),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: Text('About this course', style: AppTextStyles.h3.copyWith(color: AppColors.ink))),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.md - 4), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: Text(c.summary, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, height: 22 / 14)))),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: Text('Syllabus', style: AppTextStyles.h3.copyWith(color: AppColors.ink))),
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              for (var i = 0; i < _syllabus.length; i++)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == _syllabus.length - 1 ? Colors.transparent : AppColors.border))),
                  child: Row(
                    children: [
                      Container(width: 28, height: 28, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle), child: Text('${_syllabus[i].index}', style: AppTextStyles.label.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.semibold))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(_syllabus[i].title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14))),
                      const Icon(Ionicons.lock_closed, size: 14, color: AppColors.gray400),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final cta = PillButton(label: 'Talk to a counselor', icon: Ionicons.chatbubbles_outline, onPressed: () => context.push('/booking?kind=counseling'));

    if (expanded) {
      return AppPage(
        backLabel: 'Courses',
        backFallback: '/tabs/explore',
        scroll: false,
        body: TwoPane(
          main: main,
          side: SurfaceCard(
            radius: AppRadius.xl,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in facts) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md - 4), child: m),
                Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: cta),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: AppPage(
            backLabel: 'Courses',
            backFallback: '/tabs/explore',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TintCard(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                  child: LayoutBuilder(builder: (context, box) => Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.md - 4, children: [for (final m in facts) SizedBox(width: (box.maxWidth - AppSpacing.lg) / 2, child: m)])),
                ),
                const SizedBox(height: AppSpacing.lg),
                main,
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
          child: Align(alignment: Alignment.centerRight, child: SizedBox(width: 320, child: cta)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;
    if (c == null) {
      return const NotFoundView(
        title: 'Course not found',
        message: "This course may have been removed, or the link you followed is out of date.",
      );
    }

    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);
    if (isTablet) return _buildWide(context, c);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(bottom: AppSpacing.xxxl + AppSpacing.xxl + AppSpacing.sm + bottomInset),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, 0),
                  child: BackChevron(color: AppColors.ink, fallbackRoute: '/tabs'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CompanyMark(company: c.category, size: 56),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 18px/600 — matches Internshala's measured
                            // detail-page hero title exactly.
                            Text(c.title, style: AppTextStyles.h2.copyWith(color: AppColors.ink)),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                              child: Text(c.category, style: AppTextStyles.bodyLg.copyWith(color: AppColors.blue, fontSize: 16, fontWeight: AppFontWeight.medium)),
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
                      AppTag(label: c.category, color: AppColors.blue, bg: AppColors.blueA10),
                      const SizedBox(width: AppSpacing.sm),
                      const AppTag(label: 'Certificate included'),
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
                      _MetaRow(icon: Ionicons.time_outline, label: c.duration),
                      if (c.months > 0)
                        _MetaRow(
                          icon: Ionicons.calendar_outline,
                          label: 'About ${c.months == c.months.roundToDouble() ? c.months.round() : c.months} months',
                        ),
                      _MetaRow(icon: Ionicons.albums_outline, label: '${c.modules} modules'),
                      const _MetaRow(icon: Ionicons.ribbon_outline, label: 'Certificate on completion'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About this course', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(noOrphan(c.summary), style: AppTextStyles.body.copyWith(color: AppColors.gray500, height: 21 / 14)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: Text('Syllabus', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Column(
                          children: _syllabus
                              .map((m) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                          child: Text('${m.index}', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(m.title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14)),
                                        ),
                                        const Icon(Ionicons.lock_closed, size: 14, color: AppColors.gray400),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                    child: PillButton(
                      label: 'Talk to a counselor',
                      icon: Ionicons.chatbubbles_outline,
                      onPressed: () => context.push('/booking?kind=counseling'),
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
          Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
        ],
      ),
    );
  }
}
