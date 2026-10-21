import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'app_page.dart';

/// A white report card with a heading.
class ReportCard extends StatelessWidget {
  final String title;
  final Widget child;
  const ReportCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// The blue "YOUR RESULT" card at the top of a Career Quiz report. The one highlighted card on
/// the page.
class ReportHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? body;
  const ReportHero({super.key, required this.eyebrow, required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 12, letterSpacing: 1.4)),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(title, style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 26))),
          if (body != null && body!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(body!, style: AppTextStyles.body.copyWith(color: AppColors.whiteA70, fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }
}

/// Two columns of cards on an expanded window, one column on a medium one.
class ReportColumns extends StatelessWidget {
  final List<Widget> left;
  final List<Widget> right;
  const ReportColumns({super.key, required this.left, required this.right});

  List<Widget> _spaced(List<Widget> items) => [for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(height: AppSpacing.lg), items[i]]];

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isExpanded(context)) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced([...left, ...right]));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(left))),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(right))),
      ],
    );
  }
}
