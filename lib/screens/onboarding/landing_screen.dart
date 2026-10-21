import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/brand.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

const _heroImage = 'assets/images/landing-hero.png';

/// Single landing + auth screen: one hero, a 2-line headline, Google / phone sign-in and a link
/// for returning users. The photo bleeds edge to edge and fades into the Aerostar blue panel
/// below it. On a desktop window the photo takes the left half and the sign-in panel the right.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _googleLoading = false;

  Future<void> _continueWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final appState = context.read<AppState>();
      final user = await appState.mockGoogleSignIn();
      if (!mounted) return;
      context.go(routeForUser(user));
    } catch (_) {
      // mockGoogleSignIn is assumed to always succeed today; once real auth lands this is where a
      // genuine failure (network, cancelled consent) has to surface instead of silently resetting.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("That didn't go through — let's try again."),
          action: SnackBarAction(label: 'Retry', textColor: AppColors.yellow, onPressed: _continueWithGoogle),
          duration: const Duration(seconds: 4),
          // See sessions_screen.dart's own note on `persist`.
          persist: false,
        ),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // No `mode` query param: LoginScreen's own default is the phone field.
  void _continueWithPhone() {
    // Without this, tapping Phone right after Google (before the mock sign-in resolves) let the
    // delayed Google callback navigate away from whatever the user is now doing on the login screen.
    if (_googleLoading) return;
    context.push('/auth/login');
  }

  void _goToReturningLogin() => context.push('/auth/login?returning=1');

  Widget _actions({required bool onBlue}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(
            label: 'Continue with Google',
            // Google's "G" has its own yellow segment, which vanishes against the yellow CTA, so a
            // white badge behind it keeps the mark legible.
            iconWidget: Container(
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: SvgPicture.asset('assets/icons/google.svg'),
            ),
            loading: _googleLoading,
            onPressed: _continueWithGoogle,
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: PillButton(
              label: 'Continue with Phone Number',
              variant: onBlue ? PillVariant.outlineWhite : PillVariant.secondary,
              icon: Ionicons.call_outline,
              disabled: _googleLoading,
              onPressed: _continueWithPhone,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: _goToReturningLogin,
              // The padding lives inside the tap target: the one other action on the screen would
              // otherwise be sized to its own text line, next to two full 44px pill buttons.
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                child: Text(
                  noOrphan('Already have an account? Log in'),
                  style: AppTextStyles.body.copyWith(color: onBlue ? AppColors.white : AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.medium),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _headline({double size = 30, required bool onBlue}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manual break at a natural word boundary: letting this wrap on its own risks an orphaned
          // word alone on its own line at most screen widths.
          Text(
            'Your future job\nis looking for you too.',
            // The one marketing headline that reads as thick/bold, deliberately outside the
            // app-wide "cap at semibold" rule.
            style: AppTextStyles.h1.copyWith(color: onBlue ? AppColors.white : AppColors.ink, fontSize: size, fontWeight: AppFontWeight.extrabold, height: (size + 4) / size),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              noOrphan('Internships and jobs curated just for you.'),
              style: AppTextStyles.bodyLg.copyWith(color: onBlue ? AppColors.whiteA70 : AppColors.gray500, fontSize: 16),
            ),
          ),
        ],
      );

  /// The photo with a scrim that fades it into the blue panel: downwards on a phone or tablet,
  /// to the right on a desktop.
  Widget _hero({required bool sideways, required Color fade}) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_heroImage, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: sideways ? Alignment.centerLeft : Alignment.topCenter,
                end: sideways ? Alignment.centerRight : Alignment.bottomCenter,
                colors: [Colors.transparent, fade],
                stops: [sideways ? 0.6 : 0.55, 1.0],
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final expanded = AppBreakpoints.isExpanded(context);
    // Solid blue on a phone; on a tablet or desktop the page stays white.
    final wide = AppBreakpoints.isWide(context);
    final surface = wide ? AppColors.white : AppColors.blue;

    final logo = Positioned(
      top: topInset + AppSpacing.lg,
      left: AppSpacing.xl,
      child: const Wordmark(size: 20),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: wide ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: surface,
        body: expanded
            ? Row(
                children: [
                  Expanded(flex: 6, child: Stack(fit: StackFit.expand, children: [_hero(sideways: true, fade: surface), logo])),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _headline(size: 34, onBlue: !wide),
                              const SizedBox(height: AppSpacing.xxl),
                              _actions(onBlue: !wide),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  // The hero bleeds under the status bar on purpose: an immersive, edge-to-edge photo
                  // instead of an inset card, fading straight into the panel below.
                  SizedBox(
                    height: screenHeight * 0.5,
                    width: double.infinity,
                    child: Stack(fit: StackFit.expand, children: [_hero(sideways: false, fade: surface), logo]),
                  ),
                  Expanded(
                    child: ResponsiveBody(
                      maxWidth: AppBreakpoints.isWide(context) ? 640 : AppBreakpoints.maxContentWidth,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                        color: surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headline(onBlue: !wide),
                            // Centered in the remaining space (equal slack above and below) rather than
                            // anchored right under the subtitle.
                            const Spacer(),
                            _actions(onBlue: !wide),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomInset + AppSpacing.lg),
                ],
              ),
      ),
    );
  }
}
