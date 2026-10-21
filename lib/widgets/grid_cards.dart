import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/course.dart';
import '../models/opportunity_match.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'course_carousel_section.dart' show categoryIcons;
import 'badges.dart';
import 'company_mark.dart';
import 'pill_button.dart';

/// A job card sized by the grid it sits in (the phone's carousel card has a fixed width). Same
/// content and look as [OpportunityCarouselCard]: company mark, title, company, bookmark, city,
/// pay, match / deadline chips and an Apply button.
///
/// [compact] is the medium-window variant: the chip and a small Apply button share one row.
class OpportunityGridCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String stipend;
  final String? matchLabel;
  final String? deadlineLabel;
  final bool deadlineUrgent;
  final bool applied;
  final bool saved;
  final String? tag;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSave;

  const OpportunityGridCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.stipend,
    this.matchLabel,
    this.deadlineLabel,
    this.deadlineUrgent = false,
    this.applied = false,
    this.saved = false,
    this.tag,
    this.compact = false,
    this.onTap,
    this.onApply,
    this.onToggleSave,
  });

  List<Widget> _chips() {
    if (applied) return const [];
    final chips = <Widget>[
      if (matchLabel != null)
        Tooltip(
          message: matchExplanation,
          child: AppTag(label: matchLabel!, icon: Ionicons.information_circle_outline, compact: true),
        ),
      if (deadlineLabel != null && !compact)
        AppTag(
          label: deadlineLabel!,
          color: deadlineUrgent ? AppColors.error : AppColors.gray500,
          bg: deadlineUrgent ? AppColors.errorA10 : AppColors.gray500A15,
          compact: true,
        ),
    ];
    if (chips.isEmpty && tag != null && tag!.isNotEmpty) {
      chips.add(AppTag(label: tag!, color: AppColors.gray500, bg: AppColors.gray500A15, compact: true));
    }
    return chips;
  }

  Widget _meta(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final chips = _chips();
    final applyButton = applied
        ? PillButton(label: 'Applied', icon: Ionicons.checkmark_circle, variant: PillVariant.secondary, disabled: true, compact: compact, full: !compact, onPressed: null)
        : PillButton(label: 'Apply', variant: PillVariant.secondary, compact: compact, full: !compact, onPressed: onApply);

    return Semantics(
      button: onTap != null,
      label: '$title, $company',
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanyMark(company: company, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The company sits right under the title (the grid already makes every card in
                          // a row the same height, so no reserved second line is needed).
                          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14, height: 1.25)),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(company, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                          ),
                        ],
                      ),
                    ),
                    if (onToggleSave != null)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Semantics(
                          button: true,
                          label: saved ? 'Remove from saved' : 'Save',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onToggleSave,
                            child: Icon(saved ? Ionicons.bookmark : Ionicons.bookmark_outline, size: 20, color: saved ? AppColors.ink : AppColors.gray400),
                          ),
                        ),
                      ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Divider(height: 1, color: AppColors.border)),
                _meta(Ionicons.location_outline, location),
                _meta(Ionicons.cash_outline, stipend),
                const Spacer(),
                if (compact)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(child: chips.isEmpty ? const SizedBox.shrink() : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: chips)),
                        const SizedBox(width: AppSpacing.sm),
                        applyButton,
                      ],
                    ),
                  )
                else ...[
                  if (chips.isNotEmpty) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: chips)),
                  Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: applyButton),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A course card sized by its grid: department tag, title, duration, "View syllabus".
class CourseGridCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final bool showModules;

  /// A small grey category line above the title. Off when every card on the page is in the same category.
  final bool showCategory;

  const CourseGridCard({super.key, required this.course, required this.onTap, this.showModules = true, this.showCategory = true});

  @override
  Widget build(BuildContext context) {
    final meta = [course.duration, if (showModules) '${course.modules} modules'].join('  ·  ');
    return Semantics(
      button: true,
      label: course.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg - 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCategory)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(course.category.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 11, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
                  ),
                Text(course.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 15, height: 1.3)),
                const SizedBox(height: AppSpacing.sm),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                const Spacer(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text('View syllabus', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Ionicons.arrow_forward, size: 13, color: AppColors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
