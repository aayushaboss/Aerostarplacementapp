import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/focus_layouts.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

/// The "you reached a success state" micro-interaction after finishing a
/// level — reuses booking_confirmed_screen.dart's exact elastic-scale
/// checkmark mechanism, staged into two beats: the checkmark lands first,
/// then the title + teaser fade/slide in ~150ms later.
class CareerDnaSuccessScreen extends StatefulWidget {
  final int level;
  const CareerDnaSuccessScreen({super.key, required this.level});

  @override
  State<CareerDnaSuccessScreen> createState() => _CareerDnaSuccessScreenState();
}

class _CareerDnaSuccessScreenState extends State<CareerDnaSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _checkScale = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _contentOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _contentSlide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CareerDnaLevelMeta get _meta => careerDnaLevelMeta.firstWhere((m) => m.level == widget.level);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isLastLevel = widget.level == 5;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: FocusMessageLayout(
          mark: ScaleTransition(
            scale: _checkScale,
            child: Container(
              width: isLastLevel ? 112 : 96,
              height: isLastLevel ? 112 : 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle, boxShadow: AppShadows.brand),
              child: Icon(isLastLevel ? Ionicons.trophy : Ionicons.checkmark, size: isLastLevel ? 56 : 52, color: AppColors.ink),
            ),
          ),
          title: FadeTransition(opacity: _contentOpacity, child: Text('Level ${meta.level} complete!', style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 28))),
          message: isLastLevel ? "You've finished the whole Career Quiz journey." : 'Nicely done — your ${meta.title} results are ready.',
          primaryLabel: 'See your report',
          onPrimary: () => context.go(isLastLevel ? '/college/career-dna/final-report' : '/college/career-dna/level/${widget.level}/report'),
          secondaryLabel: isLastLevel ? 'Back to Career Quiz' : 'Back to levels',
          onSecondary: () => context.go('/tabs/career-dna'),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _checkScale,
                          child: Container(
                            width: isLastLevel ? 112 : 96,
                            height: isLastLevel ? 112 : 96,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle, boxShadow: AppShadows.yellow),
                            child: Icon(isLastLevel ? Ionicons.trophy : Ionicons.checkmark, size: isLastLevel ? 62 : 56, color: AppColors.blue),
                          ),
                        ),
                        FadeTransition(
                          opacity: _contentOpacity,
                          child: SlideTransition(
                            position: _contentSlide,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                                  child: Text(
                                    'Level ${meta.level} complete!',
                                    style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 28, fontWeight: AppFontWeight.semibold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    noOrphan(isLastLevel
                                        ? "You've finished the whole Career Quiz journey."
                                        : 'Nicely done — your ${meta.title} results are ready.'),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, bottomInset + AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                    child: Column(
                      children: [
                        PillButton(
                          label: 'See your report',
                          onPressed: () {
                            // Level 5's result is a cross-test synthesis, not a
                            // per-level report — it has its own dedicated
                            // final-report screen instead of the generic
                            // /level/:n/report route the other 4 levels use.
                            context.go(isLastLevel ? '/college/career-dna/final-report' : '/college/career-dna/level/${widget.level}/report');
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PillButton(
                          label: isLastLevel ? 'Back to Career Quiz' : 'Back to levels',
                          variant: PillVariant.secondary,
                          onPressed: () => context.go('/tabs/career-dna'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
