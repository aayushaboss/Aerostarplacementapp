import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/focus_layouts.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

class _MetaItem {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});
}

const _meta = [
  _MetaItem(icon: Ionicons.time_outline, label: '15 minutes'),
  _MetaItem(icon: Ionicons.help_circle_outline, label: '12 questions'),
  _MetaItem(icon: Ionicons.trophy_outline, label: 'Top 3 matches'),
];

/// Mirrors frontend/app/school/aptitude-intro.tsx (AptitudeIntro).
/// Aptitude is optional — users can skip and take it later from home.
class AptitudeIntroScreen extends StatelessWidget {
  const AptitudeIntroScreen({super.key});

  Future<void> _skip(BuildContext context) async {
    final appState = context.read<AppState>();
    await appState.updateProfile((current) => current.copyWith(
          aptitudeSkipped: true,
          onboardingComplete: true,
        ));
    if (!context.mounted) return;
    context.go('/tabs');
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: FocusIntroLayout(
          icon: Ionicons.bulb_outline,
          title: 'Find the stream that fits you',
          subtitle: 'A short aptitude test that maps your interests to career clusters. No wrong answers: just pick what feels like you.',
          tiles: [for (final m in _meta) FocusTile(icon: m.icon, label: m.label)],
          primaryLabel: 'Start Test',
          primaryIcon: Ionicons.play,
          onPrimary: () => context.push('/school/aptitude'),
          secondaryLabel: 'Skip for now',
          onSecondary: () => _skip(context),
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
                    const BackChevron(fallbackRoute: '/tabs'),
                    const SizedBox(height: AppSpacing.lg),
                    // Icon illustration, not a stock photo — same
                    // AppColors.whiteA10 tint as the meta-stat tiles below,
                    // so it reads as this screen's own accent rather than a
                    // dropped-in image.
                    Container(
                      width: double.infinity,
                      height: AppSpacing.xxxl * 4 + AppSpacing.sm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.whiteA10, borderRadius: BorderRadius.circular(AppRadius.xl)),
                      child: const Icon(Ionicons.bulb_outline, size: 72, color: AppColors.yellow),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          style: AppTextStyles.h1.copyWith(color: AppColors.white, height: 1.2),
                          children: const [
                            TextSpan(text: '15 minutes.\n'),
                            TextSpan(text: 'Discover what fits you.', style: TextStyle(color: AppColors.yellow)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        noOrphan('No wrong answers — just pick what feels like you.'),
                        textAlign: TextAlign.left,
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, height: 1.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxl),
                      child: Row(
                        children: _meta
                            .map(
                              (m) => Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: m == _meta.last ? 0 : AppSpacing.md),
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteA10,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(m.icon, size: 20, color: AppColors.white),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        m.label,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.white,
                                          fontWeight: AppFontWeight.medium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PillButton(
                        label: 'Start Test',
                        icon: Ionicons.play,
                        onPressed: () => context.push('/school/aptitude'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PillButton(
                        label: 'Skip for now',
                        variant: PillVariant.secondary,
                        onPressed: () => _skip(context),
                      ),
                    ],
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
