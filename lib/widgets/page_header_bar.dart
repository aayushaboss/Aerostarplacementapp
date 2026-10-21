import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// The one header for utility screens (filters, pickers, booking, edit
/// profile, ...): white, ink chevron + centered ink title, hairline divider.
/// Pages are white-dominant, so headers are never a yellow fill — yellow is
/// reserved for CTAs and highlight moments (see [AppColors]).
class PageHeaderBar extends StatelessWidget {
  final String title;

  /// Defaults to popping the route.
  final VoidCallback? onBack;

  /// Optional right-hand widget; when absent a spacer keeps the title centered.
  final Widget? trailing;

  const PageHeaderBar({super.key, required this.title, this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack ?? () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: AppSpacing.xxl,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(Ionicons.chevron_back, size: 26, color: AppColors.ink),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.semibold),
            ),
          ),
          SizedBox(width: AppSpacing.xxl, child: trailing),
        ],
      ),
    );
  }
}
