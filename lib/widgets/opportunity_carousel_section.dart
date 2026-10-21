import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/opportunity.dart';
import '../models/opportunity_match.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'carousel_section_heading.dart';
import 'opportunity_carousel_card.dart';

/// One horizontally-scrolling "topic" row on the browse feed — title, a
/// count, a "View all" link, then a fixed-height ListView of
/// [OpportunityCarouselCard]s. Naukri-style browse-by-topic instead of one
/// long vertical scroll, which stops working once there are more than a
/// screenful of postings.
class OpportunityCarouselSection extends StatelessWidget {
  final String title;
  final List<Opportunity> opportunities;
  final VoidCallback? onViewAll;

  /// How many jobs the topic really has (the lane itself only holds the first
  /// few). Shown in the heading so "Marketing jobs (300)" is not read as 10.
  final int? totalCount;
  final String? Function(Opportunity) matchLabel;
  final bool Function(Opportunity) isApplied;
  final void Function(Opportunity) onTapCard;
  final void Function(Opportunity) onApply;
  final bool Function(Opportunity)? isSaved;
  final void Function(Opportunity)? onToggleSave;

  const OpportunityCarouselSection({
    super.key,
    required this.title,
    required this.opportunities,
    required this.matchLabel,
    required this.isApplied,
    required this.onTapCard,
    required this.onApply,
    this.onViewAll,
    this.totalCount,
    this.isSaved,
    this.onToggleSave,
  });

  /// Cards shown in the lane before the trailing "View all" tile — the
  /// rest are reachable via that tile / the list screen.
  static const _visibleCap = 10;

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) return const SizedBox.shrink();

    final visible = opportunities.take(_visibleCap).toList();
    // "View all" is a trailing card in the lane (not a header link) once
    // the lane is full — per direct feedback that it reads better as the
    // 6th tile than as a small link up in the heading. `>=` (not `>`) so a
    // carousel showing exactly the cap still gets the tile: the list screen
    // it opens isn't goal-type-filtered the way this feed carousel is, so
    // it genuinely reveals more.
    final showViewAllTile = onViewAll != null && (totalCount ?? opportunities.length) >= _visibleCap;
    final itemCount = visible.length + (showViewAllTile ? 1 : 0);

    // No outer bottom padding — the carousel's own bottom shadow buffer
    // (AppSpacing.xxl, from the Row's vertical padding below) already
    // supplies the gap to whatever comes next. This section used to add
    // AppSpacing.xl on top of that too, stacking to a ~46px gap between
    // one carousel and the next — more than double every other
    // section-to-section gap on the screen once title-to-card and other
    // spots were tightened to the same "buffer alone is the gap" rule.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSectionHeading(title: title, count: totalCount ?? opportunities.length, onViewAll: onViewAll),
        // No explicit gap here — the carousel's own top padding below is
        // the gap, and it's also the shadow-safety buffer for
        // AppShadows.card (see AppShadows.cardBuffer).
        //
        // The outer AppSpacing.xl margin is deliberately split between
        // this outer Padding (AppSpacing.sm) and the ListView's own
        // start/end content padding (AppSpacing.lg) rather than living
        // entirely on one side, the way the vertical buffer does — an
        // outer-only margin narrows the ListView's viewport so its
        // edge-clip lines up with the first/last card's own edge with
        // zero room to spare, which is fine for AppShadows.card's subtle
        // 10%-alpha blur but visibly hard-cuts the "Apply" button's
        // AppShadows.brand shadow (40% alpha, so its tail is still
        // plainly visible at the same nominal blurRadius distance that
        // fully hid the card shadow's tail). Splitting it keeps the first
        // card's visible position unchanged (sm + lg == the old xl) while
        // giving the ListView's own content padding room for that
        // brighter shadow to actually fade before the clip.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: SizedBox(
            height: OpportunityCarouselCard.height + AppShadows.cardBuffer * 2,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppShadows.cardBuffer, AppSpacing.lg, AppShadows.cardBuffer),
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                if (showViewAllTile && i == visible.length) {
                  return _ViewAllTile(onTap: onViewAll!);
                }
                final o = visible[i];
                final applied = isApplied(o);
                return OpportunityCarouselCard(
                  title: o.title,
                  company: o.company,
                  location: o.location,
                  stipend: o.stipend,
                  tag: o.type,
                  matchLabel: applied ? null : matchLabel(o),
                  deadlineLabel: applied ? null : o.deadlineLabel,
                  deadlineUrgent: o.deadlineIsUrgent,
                  applied: applied,
                  saved: isSaved?.call(o) ?? false,
                  onTap: () => onTapCard(o),
                  onApply: () => onApply(o),
                  onToggleSave: onToggleSave == null ? null : () => onToggleSave!(o),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Trailing tile in a carousel lane — same card shell (width, shadow,
/// radius) as the job cards beside it, just a single centered "View all"
/// affordance. Replaces the old header "View all" link.
class _ViewAllTile extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        focusColor: AppColors.blueA10,
        child: Container(
          width: 140,
          height: OpportunityCarouselCard.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all',
                style: AppTextStyles.bodyLg.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Ionicons.arrow_forward, size: 15, color: AppColors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
