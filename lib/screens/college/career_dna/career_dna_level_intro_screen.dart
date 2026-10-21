import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/back_chevron.dart';
import '../../../widgets/focus_layouts.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

/// Per-level intro — deliberately short (per direct feedback that meta
/// chips like duration/question-count/"micro analysis" and the "no right or
/// wrong answers" box weren't needed on this kind of page): just the icon
/// tile, level eyebrow, title, what this level measures, and the Start
/// button.
class CareerDnaLevelIntroScreen extends StatelessWidget {
  final int level;
  const CareerDnaLevelIntroScreen({super.key, required this.level});

  CareerDnaLevelMeta get _meta => careerDnaLevelMeta.firstWhere((m) => m.level == level);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: FocusIntroLayout(
          icon: meta.icon,
          eyebrow: 'Level ${meta.level}',
          title: meta.title,
          subtitle: meta.whatThisMeasures,
          tiles: [
            FocusTile(icon: Ionicons.time_outline, label: meta.estTime),
            FocusTile(icon: Ionicons.help_circle_outline, label: '${meta.questionCount} questions'),
          ],
          primaryLabel: 'Start Level ${meta.level}',
          primaryIcon: Ionicons.play,
          onPrimary: () => context.push('/college/career-dna/level/${meta.level}/quiz'),
          backFallback: '/tabs/career-dna',
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackChevron(fallbackRoute: '/tabs/career-dna'),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      height: AppSpacing.xxxl * 4 + AppSpacing.sm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.whiteA10, borderRadius: BorderRadius.circular(AppRadius.xl)),
                      child: Icon(meta.icon, size: 72, color: AppColors.yellow),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: Text(
                        'Level ${meta.level}',
                        style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 1.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        noOrphan(meta.title),
                        style: AppTextStyles.h1.copyWith(color: AppColors.white, height: 1.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        noOrphan(meta.whatThisMeasures),
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                  child: PillButton(
                    label: 'Start Level ${meta.level}',
                    icon: Ionicons.play,
                    onPressed: () => context.push('/college/career-dna/level/${meta.level}/quiz'),
                  ),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
