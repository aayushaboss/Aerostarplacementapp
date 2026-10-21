import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../mockData/mock_courses.dart';
import '../../models/course.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/content_card.dart';
import '../../widgets/grid_cards.dart';
import '../../widgets/course_carousel_section.dart' show categoryIcons;
import '../../widgets/empty_state.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/responsive_body.dart';

/// Destination of the Courses search box, mirroring the jobs results screen:
/// the user types, picks a suggestion (or presses the tick), and only then
/// lands here to see "N courses found" and scroll the results.
class CourseSearchResultsScreen extends StatelessWidget {
  final String query;

  /// When set, lists exactly that department (used by a row's "View all").
  final String? category;
  const CourseSearchResultsScreen({super.key, required this.query, this.category});

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    final results = filterCoursesAdvanced(categories: category == null ? const [] : [category!], query: trimmed);
    final isTablet = AppBreakpoints.isWide(context);
    final columns = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium ? 2 : 1;

    if (isTablet) {
      final cols = AppBreakpoints.gridColumns(context);
      return AppPage(
        backLabel: 'Courses',
        backFallback: '/tabs/explore',
        title: category ?? '"$trimmed"',
        subtitle: '${results.length} ${results.length == 1 ? 'course' : 'courses'} found',
        body: results.isEmpty
            ? Padding(padding: const EdgeInsets.only(top: AppSpacing.xxl), child: EmptyState(icon: Ionicons.search_outline, title: 'No courses found', subtitle: 'No courses match "$trimmed". Try a different search term.'))
            : AppGrid(columns: cols, gap: cols > 2 ? AppSpacing.lg : AppSpacing.md, children: [for (final c in results) CourseGridCard(course: c, onTap: () => context.push('/course/${c.id}'))]),
      );
    }

    Widget card(Course c) => ContentCard(
          icon: categoryIcons[c.category],
          tag: c.category,
          title: c.title,
          meta: [c.duration, '${c.modules} modules'],
          linkLabel: 'View syllabus',
          onTap: () => context.push('/course/${c.id}'),
        );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        maxWidth: isTablet ? 1200 : 720,
        child: Column(
          children: [
            PageHeaderBar(title: category ?? '"$trimmed"', onBack: () => context.canPop() ? context.pop() : context.go('/tabs')),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${results.length} ${results.length == 1 ? 'course' : 'courses'} found',
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: EmptyState(
                          icon: Ionicons.search_outline,
                          title: 'No courses found',
                          subtitle: 'No courses match "$trimmed". Try a different search term.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
                      itemCount: (results.length / columns).ceil(),
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, row) {
                        final items = results.skip(row * columns).take(columns).toList();
                        if (columns == 1) return card(items.first);
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < columns; i++) ...[
                                if (i > 0) const SizedBox(width: AppSpacing.lg),
                                Expanded(child: i < items.length ? card(items[i]) : const SizedBox()),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
