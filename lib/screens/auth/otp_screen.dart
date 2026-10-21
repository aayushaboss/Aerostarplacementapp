import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/onboarding_frame.dart';

/// Mirrors frontend/app/auth/otp.tsx (Otp).
class OtpScreen extends StatefulWidget {
  final String identifier;

  /// Only the "I already have an account" path skips onboarding.
  final bool returning;

  const OtpScreen({super.key, required this.identifier, this.returning = false});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final _hiddenController = TextEditingController();
  final _focusNode = FocusNode();
  String _code = '';
  String? _error;
  bool _loading = false;
  int _timer = 30;
  Timer? _countdown;
  bool _resendLoading = false;
  String? _resendError;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timer > 0) setState(() => _timer--);
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _shakeController.dispose();
    _hiddenController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    // The 6-digit field auto-submits from onChanged the instant it fills,
    // and that's known to sometimes fire twice for the same final value
    // (SMS-autofill/paste on some platforms) — without this guard, a
    // second concurrent call could spuriously fail (the first call already
    // nulls the pending code on success) or double-navigate.
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    try {
      final user = await appState.verifyOtp(widget.identifier, code, returning: widget.returning);
      if (!mounted) return;
      final route = routeForUser(user);
      // `go`, not `push`, on every branch — this screen's own pending
      // code is single-use (verifyOtp nulls it on success), so leaving it
      // reachable via back would show a stale screen that throws a
      // confusing "expired" error on any second attempt. Every onboarding
      // screen already has its own explicit fallback for "nothing to pop"
      // (see BackChevron's fallbackRoute), so nothing relies on OTP
      // staying in the stack for back navigation to work correctly.
      context.go(route);
    } catch (e) {
      setState(() {
        _error = e.toString().contains('expired')
            ? "That code expired — tap resend for a new one"
            : "That code's not it — give it another go";
        _code = '';
        _hiddenController.clear();
      });
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 6 ? digits.substring(0, 6) : digits;
    setState(() {
      _code = trimmed;
      _error = null;
    });
    if (trimmed.length == 6) _verify(trimmed);
  }

  Future<void> _resend() async {
    if (_timer > 0 || _resendLoading) return;
    setState(() {
      _resendLoading = true;
      _resendError = null;
    });
    try {
      await context.read<AppState>().requestOtp(widget.identifier);
      if (!mounted) return;
      setState(() => _timer = 30);
    } catch (e) {
      if (!mounted) return;
      setState(() => _resendError = "Couldn't send a new code — try again");
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    final topInset = MediaQuery.of(context).padding.top;
    // Same identifier already used to send the code — an email sign-in
    // should never be told to "verify your number".
    final isEmail = widget.identifier.contains('@');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (wide ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light),
      child: Scaffold(
        backgroundColor: AppColors.white,
        // The six code boxes spread edge to edge, so keep this a phone-width column on a tablet.
        body: OnboardingFrame(maxWidth: 440, child: Stack(
          children: [
            Positioned(
              left: AppSpacing.lg,
              top: topInset + AppSpacing.sm,
              child: BackChevron(color: wide ? AppColors.ink : AppColors.white, fallbackRoute: '/auth/login'),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.xxxl + AppSpacing.sm, AppSpacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        color: (wide ? AppColors.ink : AppColors.white),
                        fontSize: 32,
                        fontWeight: AppFontWeight.semibold,
                        height: 38 / 32,
                      ),
                      children: [
                        const TextSpan(text: 'Verify your\n'),
                        TextSpan(
                          text: isEmail ? 'email' : 'number',
                          style: TextStyle(color: (wide ? AppColors.ink : AppColors.yellow)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'Enter the 6-digit code sent to ${widget.identifier}',
                      style: AppTextStyles.body.copyWith(color: (wide ? AppColors.gray500 : AppColors.whiteA70), fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => FocusScope.of(context).requestFocus(_focusNode),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxl),
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) {
                            final active = _code.length == i;
                            return Container(
                              width: 48,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: (wide ? AppColors.offWhite : AppColors.whiteA10),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _error != null
                                      ? AppColors.error
                                      : (active ? (wide ? AppColors.blue : AppColors.yellow) : (wide ? Colors.transparent : AppColors.whiteA20)),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                i < _code.length ? _code[i] : '',
                                style: AppTextStyles.h2.copyWith(
                                  color: (wide ? AppColors.ink : AppColors.white),
                                  fontSize: 24,
                                  fontWeight: AppFontWeight.medium,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      width: 1,
                      height: 1,
                      child: TextField(
                        controller: _hiddenController,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofocus: true,
                        autofillHints: const [],
                        decoration: const InputDecoration(counterText: ''),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        _error!,
                        style: AppTextStyles.body.copyWith(color: (wide ? AppColors.ink : AppColors.yellow), fontSize: 14, fontWeight: AppFontWeight.medium),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: PillButton(
                      label: 'Verify',
                      onPressed: () => _code.length == 6 ? _verify(_code) : null,
                      loading: _loading,
                      disabled: _code.length != 6,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: GestureDetector(
                        onTap: _resend,
                        child: _resendLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: (wide ? AppColors.ink : AppColors.whiteA70), strokeWidth: 2),
                              )
                            : Text(
                                _timer > 0 ? 'Resend code in ${_timer}s' : 'Resend code',
                                style: AppTextStyles.body.copyWith(
                                  color: _timer == 0 ? (wide ? AppColors.ink : AppColors.yellow) : (wide ? AppColors.gray500 : AppColors.whiteA70),
                                  fontSize: 14,
                                  fontWeight: AppFontWeight.medium,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_resendError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          _resendError!,
                          style: AppTextStyles.body.copyWith(color: (wide ? AppColors.ink : AppColors.yellow), fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}
