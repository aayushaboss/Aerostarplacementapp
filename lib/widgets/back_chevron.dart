import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';

/// Shared back control (matches booking header chevron).
class BackChevron extends StatelessWidget {
  final Color color;
  final VoidCallback? onPressed;
  /// Used when [onPressed] is null and the navigator cannot pop.
  final String? fallbackRoute;

  const BackChevron({
    super.key,
    this.color = AppColors.white,
    this.onPressed,
    this.fallbackRoute,
  });

  void _handle(BuildContext context) {
    HapticFeedback.selectionClick();
    if (onPressed != null) {
      onPressed!();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    final route = fallbackRoute;
    if (route != null) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handle(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(Ionicons.chevron_back, size: 26, color: color),
        ),
      ),
    );
  }
}
