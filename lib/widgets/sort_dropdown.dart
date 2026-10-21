import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Small pill-styled sort control — the current selection's label plus a
/// chevron, opening a short popup menu of options on tap. Only ever wired
/// up with options genuinely backed by real, sortable data on the screen
/// using it — never invented just to visually match a reference mockup's
/// "Sort by" control.
class SortDropdown extends StatelessWidget {
  final String value;
  final List<(String key, String label)> options;
  final ValueChanged<String> onChanged;

  /// Text before the current choice: "Sort: ", "Category: "...
  final String prefix;

  /// Height of the pill: 44 next to a search box, 40 on its own.
  final double height;

  const SortDropdown({super.key, required this.value, required this.options, required this.onChanged, this.prefix = 'Sort: ', this.height = 40});

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere((o) => o.$1 == value, orElse: () => options.first);
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      // Opens right under the pill and never taller than 360px, so a long list (13 categories)
      // scrolls inside its own panel instead of covering the page.
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 340, maxHeight: 360),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      itemBuilder: (context) => [
        for (final o in options)
          PopupMenuItem(
            value: o.$1,
            // Selected option gets a checkmark + semibold label — without this
            // the open menu gave no indication of which sort was already
            // active, unlike a standard desktop select control.
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    o.$2,
                    style: AppTextStyles.body.copyWith(
                      color: o.$1 == value ? AppColors.blue : AppColors.ink,
                      fontSize: 14,
                      fontWeight: o.$1 == value ? AppFontWeight.semibold : AppFontWeight.regular,
                    ),
                  ),
                ),
                if (o.$1 == value) const Icon(Ionicons.checkmark, size: 16, color: AppColors.blue),
              ],
            ),
          ),
      ],
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$prefix${current.$2}', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.medium)),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Ionicons.chevron_down, size: 14, color: AppColors.gray500),
          ],
        ),
      ),
    );
  }
}
