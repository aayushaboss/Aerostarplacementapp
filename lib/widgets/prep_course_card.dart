import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/course.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'course_carousel_section.dart' show categoryIcons;

/// Course row used everywhere a role's prep course gets recommended —
/// the opportunity detail page's "Prep for this role" section and the
/// applications tab's "boost your odds" upskill sheet both show the same
/// card, so the pattern lives here once instead of twice.
class PrepCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const PrepCourseCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.sm),
        // Concentric with the inner ClipRRect below: for two nested rounded
        // corners sharing a center point, outerRadius = innerRadius +
        // the padding between them (AppRadius.md + AppSpacing.sm), not an
        // unrelated token — AppRadius.xl here was 2px off from that and
        // read as a visible seam at the corner.
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.sm), boxShadow: AppShadows.soft),
        child: Row(
          children: [
            // Tinted category icon, not a stock photo — same treatment as
            // CourseCarouselSection's own card shell, so a course reads the
            // same way whether it shows up there or in this row.
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
              child: Icon(categoryIcons[course.category] ?? Ionicons.book_outline, size: 26, color: AppColors.blue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(course.title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text('${course.duration} • ${course.modules} modules', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                  ),
                ],
              ),
            ),
            const Icon(Ionicons.arrow_forward, size: 18, color: AppColors.gray500),
          ],
        ),
      ),
    );
  }
}
