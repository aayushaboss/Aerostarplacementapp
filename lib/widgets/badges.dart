import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Status values stay as-is internally (matching, counting, gating) — this
/// only softens what's shown on screen. "Rejected" reads as a personal
/// verdict at a glance, especially seeing it repeatedly; "Not selected"
/// says the same thing without the sting.
String applicationStatusLabel(String status) =>
    status == 'Rejected' ? 'Better luck next time!' : status;

/// Mirrors frontend/src/components/ui.tsx StatusBadge STATUS_COLORS + component.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  // Status badges are pure display, so they are soft tinted pills — never the
  // solid-fill look PillButton uses for a real button. In Review/Offer use the
  // *Dark variants, not the plain warning/success tokens: those read fine as
  // icon fills but fail contrast as small text on their own tint. Interview
  // gets its own violet accent instead of reusing Applied's blue, so the most
  // important status jump in a list of cards is distinguishable by color.
  static const Map<String, (Color, Color)> _statusColors = {
    'Applied': (AppColors.blueA10, AppColors.blue),
    'In Review': (AppColors.warningA15, AppColors.warningDark),
    'Interview': (AppColors.violetA15, AppColors.violet),
    'Offer': (AppColors.successA10, AppColors.successDark),
    'Rejected': (AppColors.gray500A15, AppColors.gray500),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors[status] ?? _statusColors['Applied']!;
    // Unknown statuses fall back to the Applied look.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        applicationStatusLabel(status),
        style: AppTextStyles.caption.copyWith(
          fontSize: 12,
          fontWeight: AppFontWeight.medium,
          color: fg,
        ),
      ),
    );
  }
}

/// Mirrors frontend/src/components/ui.tsx Tag. Named AppTag for consistency with AppChip.
class AppTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  /// Optional outline. Null for the usual borderless tag.
  final Color? borderColor;

  /// Optional leading glyph — e.g. for a small trust/credential badge row.
  /// Null by default so every existing call site (none of which pass one)
  /// renders exactly as before.
  final IconData? icon;

  /// Tighter horizontal padding (sm instead of md) for smaller contexts
  /// (e.g. a compact carousel card) where the default size reads as
  /// oversized against a smaller surrounding type scale. Off by default so
  /// every existing call site renders exactly as before.
  final bool compact;

  const AppTag({
    super.key,
    required this.label,
    this.color = AppColors.blue,
    this.bg = AppColors.blueA10,
    this.borderColor,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTextStyles.caption.copyWith(
        fontSize: 12,
        fontWeight: AppFontWeight.medium,
        letterSpacing: 0.3,
        color: color,
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.sm : AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 1.5),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: AppSpacing.xs),
                text,
              ],
            ),
    );
  }
}
