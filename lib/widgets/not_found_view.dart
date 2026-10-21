import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'pill_button.dart';

/// Shown instead of a permanent loading spinner when a screen looks up a
/// record (or the signed-in user) by id and finds nothing — a removed
/// application, a stale link, a signed-out session. Always gives the user
/// a way out instead of stranding them on a spinner that never resolves.
class NotFoundView extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onAction;

  const NotFoundView({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = 'Back to Home',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    void leave() => onAction != null ? onAction!() : (context.canPop() ? context.pop() : context.go('/tabs'));

    return PopScope(
      canPop: context.canPop() && onAction == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                  child: const Icon(Ionicons.alert_circle_outline, size: 34, color: AppColors.blue),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.medium)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: PillButton(label: buttonLabel, full: false, onPressed: leave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
