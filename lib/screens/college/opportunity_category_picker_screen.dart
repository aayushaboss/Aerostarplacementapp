import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../mockData/mock_profile_options.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// A flat checkbox list of every interested-role option — pushed from
/// OpportunityFilterScreen's Category row. Mechanically mirrors
/// CourseCategoryPickerScreen, backed by the same `mockAllRoles` list
/// onboarding's Goals screen and Profile Edit already use (see that
/// constant's own doc comment for why it's shared, not a new list).
class OpportunityCategoryPickerScreen extends StatefulWidget {
  final List<String> initialSelected;
  const OpportunityCategoryPickerScreen({super.key, this.initialSelected = const []});

  @override
  State<OpportunityCategoryPickerScreen> createState() => _OpportunityCategoryPickerScreenState();
}

class _OpportunityCategoryPickerScreenState extends State<OpportunityCategoryPickerScreen> {
  late List<String> _selected = [...widget.initialSelected];

  void _toggle(String role) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = _selected.contains(role) ? _selected.where((r) => r != role).toList() : [..._selected, role];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return AppPage(
        backLabel: 'Filter jobs',
        backFallback: '/tabs',
        title: 'Roles',
        subtitle: 'Select up to ${mockAllRoles.length}',
        maxWidth: AppBreakpoints.readingWidth,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < mockAllRoles.length; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggle(mockAllRoles[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == mockAllRoles.length - 1 ? Colors.transparent : AppColors.border))),
                        child: Row(
                          children: [
                            const Icon(Ionicons.briefcase_outline, size: 20, color: AppColors.gray500),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(mockAllRoles[i], style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium))),
                            Icon(_selected.contains(mockAllRoles[i]) ? Ionicons.checkbox : Ionicons.square_outline, size: 22, color: _selected.contains(mockAllRoles[i]) ? AppColors.ink : AppColors.gray400),
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
          const PageHeaderBar(title: 'Roles'),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select up to ${mockAllRoles.length}',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
              itemCount: mockAllRoles.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final role = mockAllRoles[i];
                final checked = _selected.contains(role);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(role),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Ionicons.briefcase_outline, size: 20, color: AppColors.gray500),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(role, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
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
