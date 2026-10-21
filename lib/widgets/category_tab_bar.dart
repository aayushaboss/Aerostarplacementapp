import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

class CategoryTab {
  final String key;
  final String label;
  final int count;
  const CategoryTab({required this.key, required this.label, required this.count});
}

/// Horizontal, scrollable category tab row — each tab shows a real item
/// count, one selected at a time (underlined, blue). Used wherever a
/// screen's "browse by topic" carousels become a single tabbed grid at
/// desktop widths (see college_feed_screen.dart / courses_explore_screen.dart).
class CategoryTabBar extends StatelessWidget {
  final List<CategoryTab> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryTabBar({super.key, required this.tabs, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          final tab = tabs[i];
          final isSelected = tab.key == selected;
          return GestureDetector(
            onTap: () => onSelected(tab.key),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isSelected ? AppColors.blue : Colors.transparent, width: 2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected ? AppColors.blue : AppColors.gray500,
                      fontSize: 15,
                      fontWeight: isSelected ? AppFontWeight.bold : AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '(${tab.count})',
                    style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
