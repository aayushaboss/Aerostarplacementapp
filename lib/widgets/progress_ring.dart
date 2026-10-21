import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Small circular percent-complete indicator — extracted out of
/// home_dashboard_cards.dart so the Profile tab's header can reuse it with
/// its own on-brand palette instead of a second hand-pasted copy.
class ProgressRing extends StatelessWidget {
  final int percent;
  final double size;
  final Color background;
  final Color valueColor;
  final Color textColor;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 52,
    this.background = AppColors.white,
    this.valueColor = AppColors.blue,
    this.textColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    // Was a static CircularProgressIndicator that snapped straight to
    // `value` — the same kind of ring in the Career DNA quiz
    // (career_dna_quiz_screen.dart) already animates via
    // TweenAnimationBuilder; this brings that same treatment here instead
    // of only existing in one place.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: percent / 100),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: background,
                valueColor: AlwaysStoppedAnimation(valueColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('${(value * 100).round()}%', style: AppTextStyles.caption.copyWith(color: textColor, fontSize: 12, fontWeight: AppFontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
