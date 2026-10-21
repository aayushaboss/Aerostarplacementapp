import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'brand.dart';

/// Frames an onboarding or sign-in screen on a tablet or desktop; phones get [child] untouched.
///
/// * Expanded (desktop): a quiet brand panel on the left (logo, what you
///   get) and the screen's own content in a centred column of at most [maxWidth] on the right.
/// * Medium (tablet): just the centred column.
///
/// The column keeps the height it is given, so a screen that scrolls in an Expanded and pins a
/// button underneath it keeps working inside the frame.
class OnboardingFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  /// Hide the brand panel (the "you're all set" page is already a single message).
  final bool showPanel;

  /// The screen sits on the solid Aerostar blue: the side panel is the deeper blue with white type.
  final bool onBlue;

  const OnboardingFrame({super.key, required this.child, this.maxWidth = 480, this.showPanel = true, this.onBlue = false});

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isWide(context)) return child;

    final column = LayoutBuilder(
      builder: (context, box) {
        final width = math.min(box.maxWidth, maxWidth + AppSpacing.xl * 2);
        return Padding(padding: EdgeInsets.symmetric(horizontal: (box.maxWidth - width) / 2), child: child);
      },
    );

    if (!AppBreakpoints.isExpanded(context) || !showPanel) return column;

    return Row(
      children: [
        Expanded(flex: 5, child: _BrandPanel(onBlue: onBlue)),
        Expanded(flex: 6, child: column),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final bool onBlue;
  const _BrandPanel({required this.onBlue});

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: onBlue ? AppColors.whiteA15 : AppColors.white, shape: BoxShape.circle), child: Icon(icon, size: 18, color: onBlue ? AppColors.yellow : AppColors.blue)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body.copyWith(color: onBlue ? AppColors.white : AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(body, style: AppTextStyles.body.copyWith(color: onBlue ? AppColors.whiteA70 : AppColors.gray500, fontSize: 13, height: 1.4))),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      color: onBlue ? AppColors.blueDeep : AppColors.offWhite,
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wordmark(size: 28, onBrand: onBlue),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your next opportunity starts here.', style: AppTextStyles.display.copyWith(color: onBlue ? AppColors.white : AppColors.ink, fontSize: 32, height: 1.2, fontWeight: AppFontWeight.semibold)),
                const SizedBox(height: AppSpacing.xl),
                point(Ionicons.briefcase_outline, 'Matched to your goals', 'Internships and jobs picked for your degree and interests.'),
                point(Ionicons.flash_outline, 'Apply in a tap', 'Your profile and resume travel with every application.'),
                point(Ionicons.finger_print_outline, 'Free 10 min career test', 'Find the roles you are naturally suited to.'),
              ],
            ),
          ),
          const Spacer(),
          Text("India's Startup Talent Network", style: AppTextStyles.caption.copyWith(color: onBlue ? AppColors.whiteA70 : AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
        ],
      ),
    );
  }
}
