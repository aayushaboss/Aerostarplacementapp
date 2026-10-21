import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../nav.dart';
import '../state/app_state.dart';
import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/brand.dart';
import '../widgets/responsive_body.dart';

/// Mirrors frontend/app/index.tsx (Splash). Same content as before (mark,
/// wordmark, a brief pause while the session bootstraps) — just staged as a
/// proper brand moment instead of a bare logo floating on a flat fill:
/// a clean white backdrop, ambient blurred shapes for depth, the
/// wordmark with a gentle overshoot on entry, and a small loading cue that
/// only appears once bootstrap is actually taking a beat.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _markVisible = false;
  bool _wordmarkVisible = false;
  bool _loaderVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _markVisible = true);
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _wordmarkVisible = true);
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _loaderVisible = true);
    });
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    final appState = context.read<AppState>();
    if (appState.loading) {
      final completer = Completer<void>();
      void listener() {
        if (!appState.loading) {
          appState.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        }
      }

      appState.addListener(listener);
      await completer.future;
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final route = routeForUser(appState.user);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (wide ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light),
      child: Scaffold(
        key: const ValueKey('splash-screen'),
        backgroundColor: (wide ? AppColors.white : AppColors.blue),
        body: ResponsiveBody(child: DecoratedBox(
          // Solid blue on a phone (white logo), white on a tablet or desktop.
          decoration: BoxDecoration(color: wide ? AppColors.white : AppColors.blue),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(top: -90, right: -70, child: _AmbientBlob(size: 260, color: (wide ? AppColors.offWhite : AppColors.whiteA15))),
              Positioned(bottom: -110, left: -90, child: _AmbientBlob(size: 300, color: AppColors.yellow.withValues(alpha: 0.16))),
              Center(
                child: AnimatedScale(
                  scale: _markVisible ? 1.0 : 0.55,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _markVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: AnimatedSlide(
                      offset: _wordmarkVisible ? Offset.zero : const Offset(0, 0.2),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: Wordmark(size: 40, onBrand: !wide),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                child: AnimatedOpacity(
                  opacity: _loaderVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: const Center(child: _PulsingDots()),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}

/// Soft blurred glow — ambient depth behind the mark instead of a flat
/// fill, without pulling in a new asset or painter.
class _AmbientBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _AmbientBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Three-dot loading cue — only shown once the splash has been up long
/// enough that it reads as "still working," not on every instant load.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) controller.repeat(reverse: true);
      });
      return controller;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controllers[i]),
            child: const _Dot(),
          ),
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: (wide ? AppColors.gray400 : AppColors.white), shape: BoxShape.circle),
    );
  }
}
