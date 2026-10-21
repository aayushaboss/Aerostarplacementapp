import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/career_dna_trait_summary.dart';
import 'bipolar_trait_bar.dart';

/// Brand yellow and its warm dark neutral only — never green/warning/error. Green in particular
/// (tried first) read as tied to the app's "success" status color
/// elsewhere, which is misleading here since every bar is a
/// positive-vs-positive framing, not a pass/fail signal.
const _barAccents = [AppColors.blue, AppColors.violet, AppColors.blue];

/// The compact, above-the-fold result summary shown at the top of a
/// completed level's report (and the final synthesis) — a title, 2-3
/// relative-dominance bars, and 3 lines of summary text, all sourced from
/// data/copy the app already generates elsewhere (see
/// career_dna_trait_summary.dart). No unlock/gate here — "see full report
/// below" now just means keep scrolling, since every report is free.
class CareerDnaTraitSummaryCard extends StatelessWidget {
  final CareerDnaTraitSummaryData data;
  const CareerDnaTraitSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < data.pairs.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == data.pairs.length - 1 ? 0 : AppSpacing.md),
              child: BipolarTraitBar(
                leftLabel: data.pairs[i].pair.leftLabel,
                rightLabel: data.pairs[i].pair.rightLabel,
                leftValue: data.pairs[i].leftValue,
                rightValue: data.pairs[i].rightValue,
                accentColor: _barAccents[i % _barAccents.length],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          for (final line in data.summaryLines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(line, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, height: 1.4)),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text('See full report below ↓', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
        ],
      ),
    );
  }
}
