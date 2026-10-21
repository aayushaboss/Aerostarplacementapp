import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// A drag-to-pick numeric input with the current value spelled out in full
/// above the track — used wherever a bare number field would leave the
/// reader guessing what unit they just typed (years vs. months, which
/// year). Dragging updates the label live, so the value is never ambiguous
/// the way two unlabeled text boxes were.
class LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 16)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.blue,
            inactiveTrackColor: AppColors.gray200,
            thumbColor: AppColors.blue,
            overlayColor: AppColors.blueA10,
            trackHeight: 4,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
