import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Mirrors frontend/src/components/ui.tsx Chip.
/// Named AppChip to avoid clashing with Flutter's built-in Chip widget.
///
/// Selected = solid Aerostar blue fill + white label. Unselected = neutral
/// [AppColors.offWhite] with ink label (the transparent border keeps the two
/// states the same size, so nothing shifts on tap). [onBlue] is the same chip
/// on a solid blue surface: a translucent white fill, and white when selected.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final bool disabled;
  final bool onBlue;

  /// When true, selected chips show a leading checkmark (multi-select roles).
  final bool showCheck;
  final Key? testKey;

  /// Smaller footprint for sub-tags nested under a primary chip row (e.g.
  /// interested-role filters sitting below the main type filter) — same
  /// pill, just shorter and lighter so the hierarchy between the two rows
  /// reads at a glance.
  final bool dense;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onPressed,
    this.disabled = false,
    this.onBlue = false,
    this.showCheck = false,
    this.testKey,
    this.dense = false,
  });

  void _handleTap() {
    if (disabled) return;
    HapticFeedback.selectionClick();
    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final fontWeight = selected ? AppFontWeight.semibold : AppFontWeight.medium;
    final baseBg = onBlue ? AppColors.whiteA15 : AppColors.offWhite;
    final baseFg = onBlue ? AppColors.white : AppColors.ink;
    final fg = selected ? (onBlue ? AppColors.blue : AppColors.white) : baseFg;
    final selectedBg = onBlue ? AppColors.white : AppColors.blue;

    // No Container.alignment — with an alignment + bounded max width (e.g. inside
    // Wrap), Flutter expands the chip to full row width instead of hugging text.
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        key: testKey,
        onTap: disabled ? null : _handleTap,
        child: Container(
          height: dense ? 28 : 40,
          padding: EdgeInsets.symmetric(horizontal: dense ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? selectedBg : baseBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? selectedBg : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showCheck && selected) ...[
                Icon(Ionicons.checkmark, size: dense ? 11 : AppTextStyles.body.fontSize, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: dense
                    ? AppTextStyles.caption.copyWith(fontWeight: fontWeight, color: fg, fontSize: 12)
                    : AppTextStyles.body.copyWith(fontWeight: fontWeight, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
