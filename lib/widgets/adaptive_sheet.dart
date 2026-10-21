import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// A bottom sheet on a phone and a centred dialog (max 480 wide) on a tablet or desktop. Takes
/// the same arguments as [showModalBottomSheet] so a call site only changes its name; the
/// sheet's own top-rounded [shape] is replaced by a fully rounded one on the dialog.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) {
  if (!AppBreakpoints.isWide(context)) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      shape: shape,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (dialogContext) => Dialog(
      backgroundColor: backgroundColor ?? AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85),
        child: builder(dialogContext),
      ),
    ),
  );
}
