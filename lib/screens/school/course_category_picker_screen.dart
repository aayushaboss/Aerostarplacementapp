import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../mockData/mock_courses.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/course_carousel_section.dart' show categoryIcons;
import '../../widgets/page_header_bar.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// A flat checkbox list of every course category — pushed from
/// CourseFilterScreen's Category row. Deliberately flat, not grouped under
/// parent headers the way a fuller taxonomy (e.g. Behance's job-category
/// picker) would be: the Course model only has one category level, so
/// fabricating a second, fictional one just to visually match a reference
/// isn't worth doing here.
class CourseCategoryPickerScreen extends StatefulWidget {
  final List<String> initialSelected;
  const CourseCategoryPickerScreen({super.key, this.initialSelected = const []});

  @override
  State<CourseCategoryPickerScreen> createState() => _CourseCategoryPickerScreenState();
}

class _CourseCategoryPickerScreenState extends State<CourseCategoryPickerScreen> {
  late List<String> _selected = [...widget.initialSelected];

  void _toggle(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = _selected.contains(category) ? _selected.where((c) => c != category).toList() : [..._selected, category];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return AppPage(
        backLabel: 'Filter courses',
        backFallback: '/tabs/explore',
        title: 'Categories',
        subtitle: 'Select up to ${courseCategories.length}',
        maxWidth: AppBreakpoints.readingWidth,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < courseCategories.length; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggle(courseCategories[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == courseCategories.length - 1 ? Colors.transparent : AppColors.border))),
                        child: Row(
                          children: [
                            Icon(categoryIcons[courseCategories[i]] ?? Ionicons.book_outline, size: 20, color: AppColors.gray500),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(courseCategories[i], style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium))),
                            Icon(_selected.contains(courseCategories[i]) ? Ionicons.checkbox : Ionicons.square_outline, size: 22, color: _selected.contains(courseCategories[i]) ? AppColors.ink : AppColors.gray400),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Align(alignment: Alignment.centerLeft, child: SizedBox(width: 200, child: PillButton(label: 'Done', onPressed: () => context.pop(_selected)))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        children: [
          const PageHeaderBar(title: 'Categories'),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select up to ${courseCategories.length}',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
              itemCount: courseCategories.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final category = courseCategories[i];
                final checked = _selected.contains(category);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(category),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(categoryIcons[category] ?? Ionicons.book_outline, size: 20, color: AppColors.gray500),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(category, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
                        ),
                        Icon(
                          checked ? Ionicons.checkbox : Ionicons.square_outline,
                          size: 22,
                          color: checked ? AppColors.blue : AppColors.gray400,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: PillButton(label: 'Done', onPressed: () => context.pop(_selected)),
          ),
        ],
      )),
    );
  }
}
