import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'app_page.dart';
import 'pill_button.dart';

/// One answer choice in [QuizWideLayout].
class QuizOption {
  final String key;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const QuizOption({required this.key, required this.label, required this.selected, required this.onTap});
}

/// The question screen of a quiz or test (Career Quiz levels, the school aptitude test) on a
/// tablet or desktop window. A focus screen: no navigation.
///
/// * expanded: a 320px context rail (exit, level, progress, a reassurance line) beside the
///   question, answers in a 2-column grid.
/// * medium: one centred 600px column with a progress bar across the top, answers stacked.
class QuizWideLayout extends StatelessWidget {
  final String eyebrow;
  final String title;
  final int index;
  final int total;
  final double progress;
  final String exitLabel;
  final VoidCallback onExit;
  final String helper;
  final String question;
  final List<QuizOption> options;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isLast;

  /// Shown instead of the answer grid (a slider question, say).
  final Widget? answerArea;

  const QuizWideLayout({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.index,
    required this.total,
    required this.progress,
    required this.exitLabel,
    required this.onExit,
    required this.helper,
    required this.question,
    this.options = const [],
    this.onPrevious,
    this.onNext,
    this.isLast = false,
    this.answerArea,
  });

  Widget _optionCard(QuizOption o) {
    // Same selection language as every other choice card: light gray with a crisp edge when not
    // chosen, white with a 2px yellow stroke when chosen (the border is always 2px so choosing
    // never moves anything). No drop shadow on the gray card.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: o.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: o.selected ? AppColors.blue : AppColors.offWhite,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: o.selected ? AppColors.blue : AppColors.offWhite, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: o.selected ? AppColors.whiteA20 : AppColors.white, shape: BoxShape.circle), child: Text(o.key, style: AppTextStyles.caption.copyWith(color: o.selected ? AppColors.white : AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.semibold))),
              const SizedBox(width: AppSpacing.md - 4),
              Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(o.label, style: AppTextStyles.body.copyWith(color: o.selected ? AppColors.white : AppColors.ink, fontSize: 14, height: 1.4, fontWeight: o.selected ? AppFontWeight.semibold : AppFontWeight.regular)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _answers(bool twoColumns) {
    if (answerArea != null) return answerArea!;
    if (twoColumns) {
      return AppGrid(columns: 2, gap: AppSpacing.md, children: [for (final o in options) ConstrainedBox(constraints: const BoxConstraints(minHeight: 88), child: _optionCard(o))]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final o in options) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md - 4), child: _optionCard(o))]);
  }

  Widget _footer({required double nextWidth}) {
    return Row(
      children: [
        if (onPrevious != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onPrevious,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.arrow_back, size: 16, color: AppColors.ink), const SizedBox(width: AppSpacing.xs), Text('Previous', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold))]),
              ),
            ),
          ),
        const Spacer(),
        SizedBox(width: nextWidth, child: PillButton(label: isLast ? 'Finish' : 'Next', onPressed: onNext, disabled: onNext == null)),
      ],
    );
  }

  Widget _progressBar() => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: progress.clamp(0.04, 1.0)),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: AppColors.gray100, valueColor: const AlwaysStoppedAnimation(AppColors.blue)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final expanded = AppBreakpoints.isExpanded(context);

    if (expanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 320,
            color: AppColors.offWhite,
            padding: const EdgeInsets.all(AppSpacing.xxl - 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onExit,
                      behavior: HitTestBehavior.opaque,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.close, size: 20, color: AppColors.gray500), const SizedBox(width: AppSpacing.sm), Text(exitLabel, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, fontWeight: AppFontWeight.medium))]),
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.only(top: AppSpacing.xxl), child: Text(eyebrow, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.8))),
                Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(title, style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20, height: 1.3))),
                Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: _progressBar()),
                Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('Question ${index + 1} of $total', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))),
                const Spacer(),
                Text(helper, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(question, style: AppTextStyles.h1.copyWith(color: AppColors.ink, height: 1.4)),
                      Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: _answers(true)),
                      Padding(padding: const EdgeInsets.only(top: AppSpacing.xxl - 8), child: _footer(nextWidth: 200)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Medium: progress across the top, one centred column.
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl + 8, AppSpacing.xxl, AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onExit, behavior: HitTestBehavior.opaque, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Ionicons.close, size: 24, color: AppColors.ink)))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _progressBar()),
              const SizedBox(width: AppSpacing.md),
              Text('${index + 1} / $total', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('$eyebrow · ${title.toUpperCase()}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
                      Padding(padding: const EdgeInsets.only(top: AppSpacing.md - 4), child: Text(question, style: AppTextStyles.h1.copyWith(color: AppColors.ink, height: 1.4))),
                      Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: _answers(false)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: _footer(nextWidth: 240))),
        ],
      ),
    );
  }
}
