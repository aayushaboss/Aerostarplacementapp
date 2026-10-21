import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/onboarding_frame.dart';

/// The one acknowledgment that onboarding actually finished — reached
/// right after the last required step (Goals for college/UG/PG/working,
/// Micro Profile itself for school) sets `onboardingComplete: true`, and
/// before landing on Home. Previously that transition was a bare
/// `context.go('/tabs')` with zero feedback — completing a single Career
/// DNA quiz *level* got a full celebration (career_dna_success_screen.dart)
/// while finishing the entire signup flow got nothing. Reuses that exact
/// elastic-scale checkmark mechanism rather than inventing a new one.
class OnboardingCompleteScreen extends StatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);
    final name = context.watch<AppState>().user?.name?.trim();
    final firstName = (name != null && name.isNotEmpty) ? name.split(' ').first : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (wide ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light),
      child: Scaffold(
        backgroundColor: (wide ? AppColors.white : AppColors.blue),
        body: OnboardingFrame(maxWidth: 560, showPanel: false, child: Padding(
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
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: (wide ? AppColors.brand : AppColors.yellow), shape: BoxShape.circle, boxShadow: (wide ? AppShadows.brand : AppShadows.yellow)),
                            child: Icon(Ionicons.checkmark, size: wide ? 52 : 56, color: wide ? AppColors.ink : AppColors.blue),
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
                                    firstName != null ? "You're all set, $firstName!" : "You're all set!",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.h1.copyWith(color: (wide ? AppColors.ink : AppColors.white), fontSize: 28, fontWeight: AppFontWeight.semibold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    "Your profile is ready.\nLet's find your next opportunity.",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyLg.copyWith(color: (wide ? AppColors.gray500 : AppColors.whiteA70), fontSize: 16),
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
                    child: PillButton(
                      label: "Let's go",
                      onPressed: () {
                        context.read<AppState>().markJustOnboarded();
                        context.go('/tabs');
                      },
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
