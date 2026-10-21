import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/opportunity_match.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'badges.dart';
import 'company_mark.dart';
import 'pill_button.dart';

/// Fixed-width job card for a horizontal carousel row — the same
/// information as [OpportunityRow] (role, company, location, stipend,
/// urgency), just reflowed for a Naukri-style "scroll sideways within a
/// topic" browse pattern instead of one long vertical feed.
///
/// [height] is fixed (carousel cards in one row need to line up). Every
/// piece of content that can vary in size between two real cards —
/// [_titleHeight] (a 1-line vs. a 2-line title) and [_statusHeight] (the
/// "Applied" chip is always one line, but two chips like "75% match" +
/// "4 days left" can wrap to two) — gets a fixed, reserved height instead
/// of a natural/intrinsic one, so the content block above the button sums
/// to the *same* total for every card regardless of its data. A `Spacer`
/// between that block and the button is what actually pins the button to
/// the card's bottom edge; it's safe here specifically because that sum is
/// now constant — the previous version's bug was a `Spacer` paired with
/// content whose height genuinely varied (an applied card's chip row
/// disappeared entirely instead of reserving space), not the `Spacer`
/// itself.
class OpportunityCarouselCard extends StatelessWidget {
  static const double width = 250;

  // Real headroom, not a tight fit — this card's own history already
  // learned this lesson once (height bumped 222 → 262 → 290 after the
  // 2-line-title + tags-row combination kept overflowing a "just barely
  // fits" budget).
  static const double height = 260;

  // 2 lines at the title's own 15px/1.25 line-height (≈18.75px/line) —
  // reserved unconditionally so a 1-line title leaves identical space
  // below it as a 2-line one.
  static const double _titleHeight = 38;

  // Worst case for the status chip row: two compact chips wrapping to two
  // lines (24px each + 4px runSpacing). Reserved unconditionally so the
  // single-line "Applied" chip doesn't leave the card shorter than a
  // two-chip card.
  static const double _statusHeight = 52;

  final String title;
  final String company;
  final String location;
  final String stipend;
  final String? matchLabel;
  final String? deadlineLabel;
  final bool deadlineUrgent;
  final bool applied;
  final bool saved;

  /// Fallback status-chip text (e.g. "Internship") shown when there's no
  /// match score, no deadline, and it isn't applied.
  final String? tag;

  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSave;

  const OpportunityCarouselCard({
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
    this.onTap,
    this.onApply,
    this.onToggleSave,
  });

  Widget _statusChip() {
    // Applied cards show no status chip: the footer button already reads
    // "Applied", and repeating it as a chip said the same thing twice.
    if (applied) return const SizedBox.shrink();
    final chips = <Widget>[
      if (matchLabel != null)
        Tooltip(
          message: matchExplanation,
          triggerMode: TooltipTriggerMode.tap,
          child: AppTag(label: matchLabel!, icon: Ionicons.information_circle_outline, compact: true),
        ),
      if (deadlineLabel != null)
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
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: chips);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title, $company',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          // Visible on keyboard focus — see opportunity_row.dart's own note.
          focusColor: AppColors.blueA10,
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              // Not mainAxisSize.min — the Spacer before the button needs
              // this Column filling the Container's fixed height (bounded,
              // tight constraints already) to know how much leftover space
              // to absorb.
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: _titleHeight,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14, height: 1.25),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onToggleSave != null)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onToggleSave,
                          child: Icon(
                            saved ? Ionicons.bookmark : Ionicons.bookmark_outline,
                            size: 20,
                            color: saved ? AppColors.blue : AppColors.gray400,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                // City on one line and pay on the next: the spreadsheet's pay text is
                // long ("₹17,000–₹25,000/month"), and beside the city it squeezed the
                // city down to "Be…". The card already had room for the extra line.
                Row(
                  children: [
                    const Icon(Ionicons.location_outline, size: 14, color: AppColors.gray500),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      const Icon(Ionicons.cash_outline, size: 14, color: AppColors.gray500),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          stipend,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: SizedBox(
                    height: _statusHeight,
                    child: Align(alignment: Alignment.topLeft, child: _statusChip()),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: applied
                      ? const PillButton(
                          label: 'Applied',
                          icon: Ionicons.checkmark_circle,
                          variant: PillVariant.secondary,
                          disabled: true,
                          onPressed: null,
                        )
                      : PillButton(label: 'Apply', variant: PillVariant.secondary, onPressed: onApply),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
