import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/opportunity_match.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'badges.dart';
import 'pill_button.dart';

/// Mirrors frontend/src/components/ContentCard.tsx.
///
/// A leading tinted icon mark next to the title, then a body that
/// deliberately reuses OpportunityRow's exact language (tag pill, bold
/// title, icon+text meta row, "View X →" link footer) — this is the same
/// card family as the job cards and CourseCarouselSection's course cards,
/// not a different design system with a photo bolted on.
class ContentCard extends StatefulWidget {
  final IconData? icon;
  final String? tag;
  final String title;
  final String? subtitle;
  final List<String> meta;
  final String linkLabel;
  final VoidCallback? onTap;
  final bool saved;
  final bool applied;
  final VoidCallback? onToggleSave;
  final Key? testKey;

  /// Personalized relevance badge (e.g. "Great fit", "72% match"). Optional —
  /// only opportunity cards with a signed-in user's roles/resume set this.
  final String? matchLabel;

  /// Application-deadline urgency badge (e.g. "2 days left"). Optional.
  final String? deadlineLabel;

  /// Styles [deadlineLabel] with the error color instead of warning when true.
  final bool deadlineUrgent;

  const ContentCard({
    super.key,
    this.icon,
    this.tag,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.linkLabel = 'View details',
    this.onTap,
    this.saved = false,
    this.applied = false,
    this.onToggleSave,
    this.testKey,
    this.matchLabel,
    this.deadlineLabel,
    this.deadlineUrgent = false,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  static const _metaIcons = [Ionicons.time_outline, Ionicons.albums_outline, Ionicons.ribbon_outline];


  // A card is the single most-tapped surface in the app and previously
  // got only InkWell's stock ripple, no custom feedback — PillButton
  // already has a proven scale-down-on-press pattern; this reuses it via
  // InkWell's own onHighlightChanged rather than layering a second,
  // competing gesture detector over the tap surface.
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final chips = widget.meta.where((m) => m.trim().isNotEmpty).toList();
    final deadlineColor = widget.deadlineUrgent ? AppColors.error : AppColors.gray500;

    return Semantics(
      button: widget.onTap != null,
      label: widget.subtitle == null || widget.subtitle!.isEmpty ? widget.title : '${widget.title}, ${widget.subtitle}',
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
        // Concentric with the icon mark's own AppRadius.md corner sitting
        // AppSpacing.lg inside it — matches _ApplicationCard's identical
        // rounding, per direct feedback that Courses' cards should read as
        // the same card family as Applications', not a flatter cousin.
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg), color: AppColors.white, boxShadow: AppShadows.card),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.white,
          child: InkWell(
            key: widget.testKey,
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            // Visible on keyboard focus — see opportunity_row.dart's own note.
            focusColor: AppColors.blueA10,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        // Neutral circle + gray glyph, matching the course carousel
                        // card and the Notifications rows.
                        decoration: BoxDecoration(color: AppColors.violetA15, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Icon(widget.icon ?? Ionicons.book_outline, size: 22, color: AppColors.violet),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
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
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                // 14px/semibold — matches Internshala's
                                // measured card title (14px/600).
                                style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14),
                              ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (var i = 0; i < chips.length; i++)
                            _MetaItem(icon: i < _metaIcons.length ? _metaIcons[i] : Ionicons.ellipse_outline, label: chips[i]),
                        ],
                      ),
                    ),
                  if (widget.matchLabel != null || widget.deadlineLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (widget.matchLabel != null)
                            Tooltip(
                              message: matchExplanation,
                              // tap, not the default long-press — see the
                              // same fix on OpportunityCarouselCard.
                              triggerMode: TooltipTriggerMode.tap,
                              child: _MetaItem(icon: Ionicons.star, label: widget.matchLabel!, color: AppColors.blue),
                            ),
                          if (widget.deadlineLabel != null) _MetaItem(icon: Ionicons.time_outline, label: widget.deadlineLabel!, color: deadlineColor),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.linkLabel,
                                style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(Ionicons.arrow_forward, size: 13, color: AppColors.blue),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.applied)
                          const PillButton(
                            label: 'Applied',
                            icon: Ionicons.checkmark_circle,
                            variant: PillVariant.secondary,
                            full: false,
                            compact: true,
                            disabled: true,
                            onPressed: null,
                          ),
                      ],
                    ),
                ],
              ),
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
