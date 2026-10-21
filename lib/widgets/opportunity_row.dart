import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/opportunity_match.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'badges.dart';
import 'pill_button.dart';

/// Standalone job/internship card — a colored type tag up top, bold title,
/// an icon+text meta row (location, stipend, duration), then a footer with
/// a "View details" link and an Apply CTA. Each card is its own bordered,
/// rounded block with a gap to the next one, not a divided list row.
class OpportunityRow extends StatefulWidget {
  final String? tag;
  final String title;
  final String? subtitle;
  final List<String> meta;
  final VoidCallback? onTap;
  final bool saved;
  final bool applied;
  final VoidCallback? onToggleSave;
  final Key? testKey;
  final String? matchLabel;
  final String? deadlineLabel;
  final bool deadlineUrgent;

  /// When set, a footer row (View details / Apply) is shown below the card
  /// — omitted for compact reuse contexts (e.g. the detail page's Similar
  /// roles strip) where a second Apply CTA would be redundant.
  final VoidCallback? onApply;

  /// Opt-in only — when set, wraps the title in a Hero with this tag so
  /// tapping into the matching detail screen (which must use the exact
  /// same tag on its own title) animates as one continuous element
  /// instead of a hard cut. Left null by default so reuse contexts that
  /// show the same opportunity twice on one screen at once (e.g. a
  /// "Similar roles" strip on the detail page itself) can't collide with
  /// another Hero using the same tag.
  final Object? heroTag;

  const OpportunityRow({
    super.key,
    // Accepted for backwards compatibility with existing call sites that
    // still pass a thumbnail URL — the card no longer renders an image.
    String? image,
    this.tag,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.onTap,
    this.saved = false,
    this.applied = false,
    this.onToggleSave,
    this.testKey,
    this.matchLabel,
    this.deadlineLabel,
    this.deadlineUrgent = false,
    this.onApply,
    this.heroTag,
  });

  @override
  State<OpportunityRow> createState() => _OpportunityRowState();
}

class _OpportunityRowState extends State<OpportunityRow> {
  static const _metaIcons = [Ionicons.location_outline, Ionicons.cash_outline, Ionicons.time_outline];
  // Same reasoning as ContentCard's identical field — see that file's note.
  bool _pressed = false;

  Widget _titleText(Object? heroTag) {
    final text = Text(
      widget.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      // 14px/semibold — matches Internshala's measured job-card title
      // (14px/600).
      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14),
    );
    if (heroTag == null) return text;
    return Hero(tag: heroTag, child: Material(color: Colors.transparent, child: text));
  }

  @override
  Widget build(BuildContext context) {
    final deadlineColor = widget.deadlineUrgent ? AppColors.error : AppColors.gray500;

    return Semantics(
      button: widget.onTap != null,
      label: widget.subtitle == null || widget.subtitle!.isEmpty ? widget.title : '${widget.title}, ${widget.subtitle}',
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: widget.testKey,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          // Visible on keyboard focus (InkWell already supports Tab-focus and
          // paints this automatically) — Round V's accessibility bootstrap;
          // no new interaction, just making the built-in behavior visible.
          focusColor: AppColors.blueA10,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.tag != null && widget.tag!.isNotEmpty) AppTag(label: widget.tag!),
                    const Spacer(),
                    if (widget.onToggleSave != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onToggleSave,
                        child: Icon(
                          widget.saved ? Ionicons.bookmark : Ionicons.bookmark_outline,
                          size: 18,
                          color: widget.saved ? AppColors.blue : AppColors.gray400,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _titleText(widget.heroTag),
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                    ),
                  ),
                if (widget.meta.where((m) => m.trim().isNotEmpty).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (var i = 0; i < widget.meta.length; i++)
                          if (widget.meta[i].trim().isNotEmpty)
                            _MetaItem(icon: i < _metaIcons.length ? _metaIcons[i] : Ionicons.ellipse_outline, label: widget.meta[i]),
                      ],
                    ),
                  ),
                if (!widget.applied && (widget.matchLabel != null || widget.deadlineLabel != null))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (widget.matchLabel != null)
                          Tooltip(
                            message: matchExplanation,
                            // tap, not the default long-press — see the same
                            // fix on OpportunityCarouselCard.
                            triggerMode: TooltipTriggerMode.tap,
                            child: _MetaItem(icon: Ionicons.star, label: widget.matchLabel!, color: AppColors.blue),
                          ),
                        if (widget.deadlineLabel != null) _MetaItem(icon: Ionicons.time_outline, label: widget.deadlineLabel!, color: deadlineColor),
                      ],
                    ),
                  ),
                if (widget.onApply != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View details',
                                style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(Ionicons.arrow_forward, size: 13, color: AppColors.blue),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.applied)
                          PillButton(
                            label: 'Applied',
                            icon: Ionicons.checkmark_circle,
                            variant: PillVariant.secondary,
                            full: false,
                            compact: true,
                            disabled: true,
                            onPressed: null,
                          )
                        else
                          PillButton(label: 'Apply', variant: PillVariant.secondary, full: false, compact: true, onPressed: widget.onApply),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaItem({required this.icon, required this.label, this.color = AppColors.gray500});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: color, fontSize: 12, fontWeight: AppFontWeight.medium),
        ),
      ],
    );
  }
}
