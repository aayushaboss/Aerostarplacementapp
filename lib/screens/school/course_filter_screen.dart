import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../mockData/mock_courses.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_page.dart';
import '../../widgets/field_label.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// Everything the Filter screen can select on, and its Apply result —
/// [isEmpty] means "no filters active" (same as never having opened this
/// screen), used by CoursesExploreScreen to decide whether to show the
/// unfiltered carousel stack or a flat filtered result list.
class CourseFilterSelection {
  final List<String> categories;
  final List<String> durationBuckets;

  const CourseFilterSelection({this.categories = const [], this.durationBuckets = const []});

  bool get isEmpty => categories.isEmpty && durationBuckets.isEmpty;
}

/// Mirrors the shape of a Behance-style job filter screen (stacked facet
/// rows, one of which opens a dedicated picker screen; a Reset/Apply bottom
/// bar) adapted to the Course model's actual, flat taxonomy: Category (opens
/// CourseCategoryPickerScreen) and Duration (small enough — 3 values — to
/// stay inline as an inspectable-at-a-glance chip row rather than needing
/// its own picker screen too).
class CourseFilterScreen extends StatefulWidget {
  final CourseFilterSelection initial;
  const CourseFilterScreen({super.key, this.initial = const CourseFilterSelection()});

  @override
  State<CourseFilterScreen> createState() => _CourseFilterScreenState();
}

class _CourseFilterScreenState extends State<CourseFilterScreen> {
  late List<String> _categories = [...widget.initial.categories];
  late List<String> _durationBuckets = [...widget.initial.durationBuckets];

  Future<void> _pickCategories() async {
    final result = await context.push<List<String>>('/school/course-category-picker', extra: _categories);
    if (result != null) setState(() => _categories = result);
  }

  void _toggleDuration(String bucket) {
    setState(() => _durationBuckets = _durationBuckets.contains(bucket) ? _durationBuckets.where((b) => b != bucket).toList() : [..._durationBuckets, bucket]);
  }

  void _reset() {
    setState(() {
      _categories = [];
      _durationBuckets = [];
    });
  }

  void _apply() {
    context.pop(CourseFilterSelection(categories: _categories, durationBuckets: _durationBuckets));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final categoryLabel = _categories.isEmpty ? 'All categories' : _categories.join(', ');
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return AppPage(
        backLabel: 'Courses',
        backFallback: '/tabs/explore',
        title: 'Filter courses',
        maxWidth: AppBreakpoints.readingWidth,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('Category', tight: true),
            GestureDetector(
              onTap: _pickCategories,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    const Icon(Ionicons.book_outline, size: 18, color: AppColors.gray500),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(categoryLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg.copyWith(fontSize: 16, color: _categories.isEmpty ? AppColors.gray400 : AppColors.ink))),
                    const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
            const FieldLabel('Duration'),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final b in courseDurationBuckets) AppChip(label: b, selected: _durationBuckets.contains(b), showCheck: true, onPressed: () => _toggleDuration(b))]),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                SizedBox(width: 140, child: PillButton(label: 'Reset', variant: PillVariant.secondary, onPressed: _reset)),
                const SizedBox(width: AppSpacing.md),
                SizedBox(width: 200, child: PillButton(label: 'Apply', onPressed: _apply)),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        children: [
          const PageHeaderBar(title: 'Filter courses'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                const FieldLabel('Category', tight: true),
                GestureDetector(
                  onTap: _pickCategories,
                  child: Container(
                    // Matches DatePickerField's shell exactly (pill, no
                    // border, fixed height, leading icon) — the app's actual
                    // "tap to pick a value" field convention, rather than the
                    // bordered rounded-box family used elsewhere only for
                    // floating dropdown panels. chevron_forward (not
                    // DatePickerField's chevron_down) stays, since that's the
                    // app's own convention for a row that pushes a new
                    // screen rather than opening a bottom sheet.
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: [
                        const Icon(Ionicons.book_outline, size: 18, color: AppColors.gray500),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            categoryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _categories.isEmpty
                                ? AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.gray400, fontWeight: AppFontWeight.regular)
                                : AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.ink),
                          ),
                        ),
                        const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                      ],
                    ),
                  ),
                ),
                const FieldLabel('Duration'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: courseDurationBuckets
                      .map((b) => AppChip(label: b, selected: _durationBuckets.contains(b), showCheck: true, onPressed: () => _toggleDuration(b)))
                      .toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: PillButton(label: 'Reset', variant: PillVariant.secondary, onPressed: _reset)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 3, child: PillButton(label: 'Apply', onPressed: _apply)),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
