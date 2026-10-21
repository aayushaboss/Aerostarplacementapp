import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// The one progress bar shared by every onboarding step, so the student always
/// sees where they are and how much is left. The bar covers the whole flow, not
/// just the current screen: it only reaches 100% when the last step is done.
///
/// [step] is 1-based; [stepFill] (0 to 1) is how much of the current step is
/// filled in, so the bar still moves as they answer.
class OnboardingProgress extends StatelessWidget {
  final int step;
  final int totalSteps;
  final double stepFill;

  const OnboardingProgress({super.key, required this.step, required this.totalSteps, this.stepFill = 0});

  @override
  Widget build(BuildContext context) {
    final overall = ((step - 1) + stepFill.clamp(0.0, 1.0)) / totalSteps;
    return Semantics(
      label: 'Step $step of $totalSteps',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm / 2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: overall.clamp(0.04, 1.0)),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: AppSpacing.sm - AppSpacing.xs / 2,
                  backgroundColor: AppColors.gray100,
                  valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('Step $step of $totalSteps', style: AppTextStyles.label.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
        ],
      ),
    );
  }
}
