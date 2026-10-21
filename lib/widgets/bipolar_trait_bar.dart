import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// A two-ended, MBTI-style result bar ("Extrovert 62% / Introvert") — shows
/// which of two already-scored dimensions pulls relatively stronger for a
/// student, not a claim of true bipolar opposite-pole psychometrics. Both
/// labels are always positively framed; the split itself is the data, so
/// the bar is two proportioned segments rather than one fill+track.
class BipolarTraitBar extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final int leftValue;
  final int rightValue;
  /// Fill of the dominant segment only; labels stay ink so a light accent
  /// (brand yellow) never becomes text on white.
  final Color accentColor;

  const BipolarTraitBar({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = leftValue + rightValue;
    final leftShare = total == 0 ? 0.5 : leftValue / total;
    final leftDominant = leftShare >= 0.5;
    final dominantPercent = (leftDominant ? leftShare : 1 - leftShare) * 100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: leftShare),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedLeftShare, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  leftLabel,
                  style: AppTextStyles.body.copyWith(
                    color: leftDominant ? AppColors.ink : AppColors.gray500,
                    fontSize: 13,
                    fontWeight: leftDominant ? AppFontWeight.semibold : AppFontWeight.regular,
                  ),
                ),
                if (leftDominant) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text('${dominantPercent.round()}%', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.semibold)),
                ],
                const Spacer(),
                if (!leftDominant) ...[
                  Text('${dominantPercent.round()}%', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.semibold)),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  rightLabel,
                  style: AppTextStyles.body.copyWith(
                    color: !leftDominant ? AppColors.ink : AppColors.gray500,
                    fontSize: 13,
                    fontWeight: !leftDominant ? AppFontWeight.semibold : AppFontWeight.regular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(flex: (animatedLeftShare * 1000).round().clamp(1, 999), child: Container(color: leftDominant ? accentColor : AppColors.gray200)),
                    Expanded(flex: (1000 - (animatedLeftShare * 1000).round()).clamp(1, 999), child: Container(color: leftDominant ? AppColors.gray200 : accentColor)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
