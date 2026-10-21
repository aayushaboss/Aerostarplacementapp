import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Heading for a horizontal carousel row on the feeds — plain black title,
/// 16px, an optional grey count following it. Carries its own top clearance
/// so every carousel on the feed reads as a separate block from the one
/// above it, not just a heading floating directly above a card row. This is
/// the single place that gap lives — callers should NOT also add their own
/// inter-section SizedBox before a carousel, or the gap doubles.
///
/// No divider — a previous version had one above the title, but paired with
/// a heading immediately underneath it read as two competing section
/// markers for the same break. The top padding alone is the separation now.
class CarouselSectionHeading extends StatelessWidget {
  final String title;
  final int? count;

  /// When set, a "View all" link sits at the right end of the heading row, so a
  /// visitor can jump to the full list without scrolling to the trailing tile.
  final VoidCallback? onViewAll;

  const CarouselSectionHeading({
    super.key,
    required this.title,
    this.count,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder, not SizedBox(width: double.infinity) — the latter
    // measured inconsistently per instance in practice (this Column only
    // ever receives LOOSE width constraints from its section's own Column,
    // crossAxisAlignment.start). LayoutBuilder reads the real, resolved
    // `constraints.maxWidth` directly and pins the row/divider to exactly
    // that — deterministic regardless of how the ambient loose constraint
    // resolves, unlike double.infinity's reliance on that being unambiguous.
    // (There used to be a "View all" link rendered here too — removed: it
    // duplicated, and could never pixel-match, the trailing "View all" tile
    // that's already the last card in the row below — see
    // opportunity_carousel_section.dart's/course_carousel_section.dart's
    // own _ViewAllTile/_CourseViewAllTile, which is the sole "View all"
    // affordance now.)
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // md + xs (16 + 4 = 20) — the plain md gap read as too
                // tight once the divider that used to sit above the
                // heading was removed; +4dp per direct feedback.
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md + AppSpacing.xs,
                  AppSpacing.xl,
                  0,
                ),
                child: SizedBox(
                  width: constraints.maxWidth - AppSpacing.xl * 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // Title + count take all the room the link leaves, so a long
                      // department name shortens only when it truly cannot fit.
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.ink,
                                  fontSize: 16,
                                  fontWeight: AppFontWeight.semibold,
                                ),
                              ),
                            ),
                            if (count != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '($count)',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.gray500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onViewAll != null)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onViewAll,
                          child: Padding(
                            // Padding inside the tap target: a full-size touch area.
                            padding: const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.xs, bottom: AppSpacing.xs),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View all',
                                  style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(Ionicons.arrow_forward, size: 14, color: AppColors.blue),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
