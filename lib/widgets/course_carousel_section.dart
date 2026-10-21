import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../models/course.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'carousel_section_heading.dart';

/// One icon per course department (the 17 in the course sheet). Unknown
/// departments fall back to a book icon where this map is read.
const categoryIcons = {
  'Marketing': Ionicons.megaphone_outline,
  'Digital Marketing': Ionicons.globe_outline,
  'Social Media Marketing': Ionicons.share_social_outline,
  'Sales & Business Development': Ionicons.trending_up_outline,
  'Business Analytics': Ionicons.bar_chart_outline,
  'Human Resources': Ionicons.people_outline,
  'Project Management': Ionicons.clipboard_outline,
  'Founder / Startup Skills': Ionicons.rocket_outline,
  'Supply Chain & Logistics': Ionicons.cube_outline,
  'AI for Business': Ionicons.hardware_chip_outline,
  'Finance & Accounting': Ionicons.cash_outline,
  'Operations': Ionicons.settings_outline,
  'Graphic Designing': Ionicons.color_palette_outline,
  'E-Commerce': Ionicons.cart_outline,
  'Product Management': Ionicons.layers_outline,
  'Business Strategy': Ionicons.compass_outline,
  'Customer Success': Ionicons.happy_outline,
};

/// One horizontally-scrolling row of course cards — promoted out of
/// courses_explore_screen.dart (where it was a private, header-less,
/// category-only carousel) so the Home feed's end-of-scroll "Boost your
/// chances" section can reuse the exact same card shell with a title/count/
/// "View all" header added, mirroring OpportunityCarouselSection's shape.
/// [onViewAll] is optional — courses_explore_screen.dart's own per-category
/// carousels pass none, since that screen already *is* the "view all"
/// destination.
class CourseCarouselSection extends StatelessWidget {
  final String title;
  final List<Course> courses;
  final VoidCallback? onViewAll;

  /// How many cards the row shows before "View all". The Courses page raises
  /// this so every course in a department is reachable.
  final int visibleCap;

  const CourseCarouselSection({super.key, required this.title, required this.courses, this.onViewAll, this.visibleCap = 5});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final visible = courses.take(visibleCap).toList();
    final showViewAllTile = onViewAll != null && courses.length >= visibleCap;
    final itemCount = visible.length + (showViewAllTile ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSectionHeading(title: title, count: courses.length, onViewAll: onViewAll),
        // No explicit gap here — the carousel's own top padding below is
        // the gap, and it's also the shadow-safety buffer for
        // AppShadows.card (see AppShadows.cardBuffer).
        //
        // Horizontal inset is split sm (outer) + lg (ListView's own content
        // padding) rather than living entirely in the outer Padding — a
        // ListView clips to its own box regardless of an outer Padding's
        // width, so the first/last card's shadow (needs ~12px clearance
        // left/right, blurRadius with zero x-offset) was hard-clipped with
        // no padding of the ListView's own. sm+lg still sums to the usual
        // AppSpacing.xl total inset; same split already used correctly in
        // opportunity_carousel_section.dart's lane.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: SizedBox(
            height: 196 + AppShadows.cardBuffer * 2,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppShadows.cardBuffer, AppSpacing.lg, AppShadows.cardBuffer),
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                if (showViewAllTile && i == visible.length) {
                  return _CourseViewAllTile(onTap: onViewAll!);
                }
                return _CourseCard(course: visible[i]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Same shell as OpportunityCarouselCard on the Home feed (fixed
/// width/height, AppShadows.card, tinted icon mark instead of a photo) —
/// deliberately the same card family, not a bespoke look for courses.
class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
      child: InkWell(
        onTap: () => context.push('/course/${course.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        child: Container(
          width: 250,
          // Bumped 172->196 for the 8pt spacing-grid pass — the card's own
          // internal AppSpacing paddings grew, and 172 no longer fits its
          // content without clipping.
          height: 196,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // Centre the title against the icon mark — a 1-line title
                // top-aligned next to a 44px mark left an odd gap beneath it.
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    // Neutral circle + gray glyph, the same icon treatment as the
                    // Notifications rows. The circle (vs a job card's square company
                    // mark) is what tells a course apart from a job at a glance.
                    decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                    child: Icon(categoryIcons[course.category] ?? Ionicons.book_outline, size: 22, color: AppColors.blue),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // 14px/semibold — matches Internshala's measured
                      // card title (14px/600).
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14, height: 1.2),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _MetaLine(icon: Ionicons.time_outline, label: course.duration),
              const SizedBox(height: AppSpacing.sm),
              _MetaLine(icon: Ionicons.layers_outline, label: '${course.modules} modules'),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('View syllabus →', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing "View all" tile for a course lane — matches _CourseCard's
/// shell, single centered affordance.
class _CourseViewAllTile extends StatelessWidget {
  final VoidCallback onTap;
  const _CourseViewAllTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        focusColor: AppColors.blueA10,
        child: Container(
          width: 140,
          height: 196,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View all', style: AppTextStyles.bodyLg.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Ionicons.arrow_forward, size: 15, color: AppColors.blue),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.gray500),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
          ),
        ),
      ],
    );
  }
}
