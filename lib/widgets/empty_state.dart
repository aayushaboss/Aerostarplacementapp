import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'pill_button.dart';

/// Inline sibling to [NotFoundView] — same exact visual constants (72×72
/// offWhite circle, 34px ink icon, h3/18px/medium title, body/gray500/14px
/// subtitle, optional PillButton), but embeddable inside any existing
/// ListView/Column instead of owning a whole Scaffold. [NotFoundView] stays
/// the right shape for a genuine "record not found" full-screen case; this
/// is for "this list has nothing in it yet."
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
          child: Icon(icon, size: 34, color: AppColors.blue),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.medium)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
          ),
        ),
        if (buttonLabel != null && onButtonTap != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: PillButton(label: buttonLabel!, full: false, onPressed: onButtonTap),
          ),
      ],
    );
  }
}
