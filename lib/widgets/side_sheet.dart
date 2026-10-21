import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'pill_button.dart';

/// A 400px panel that slides in from the right over a dimmed page (the tablet version of a
/// filter screen), with a close button, a scrolling body and a Reset / Apply footer.
///
/// [content] builds the body and receives a `setSheet` to refresh it while the sheet is open;
/// [onReset] clears the sheet's own working copy; [onApply] commits it (the sheet closes after).
Future<void> showSideSheet({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context, StateSetter setSheet) content,
  required void Function(StateSetter setSheet) onReset,
  required VoidCallback onApply,
  String applyLabel = 'Apply',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x521C1C1E),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.white,
        child: SizedBox(
          width: 400,
          height: double.infinity,
          child: StatefulBuilder(
            builder: (context, setSheet) => Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: AppTextStyles.h2.copyWith(color: AppColors.ink))),
                      Semantics(button: true, label: 'Close', child: GestureDetector(onTap: () => Navigator.of(dialogContext).pop(), child: const Icon(Ionicons.close, size: 24, color: AppColors.ink))),
                    ],
                  ),
                ),
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm), child: content(context, setSheet))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                  child: Row(
                    children: [
                      GestureDetector(onTap: () => onReset(setSheet), child: Text('Reset', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium))),
                      const Spacer(),
                      SizedBox(
                        width: 160,
                        child: PillButton(
                          label: applyLabel,
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            onApply();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) => SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child),
  );
}

/// A plain checkbox row used in filter lists: 2px yellow border and an ink check when on.
class FilterCheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  const FilterCheckRow({super.key, required this.label, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        checked: checked,
        label: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: checked ? AppColors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: checked ? AppColors.blue : AppColors.gray200, width: 1.5),
                  ),
                  child: checked ? const Icon(Ionicons.checkmark, size: 13, color: AppColors.white) : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
