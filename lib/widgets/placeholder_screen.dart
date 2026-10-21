import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Stand-in destination for routes whose real screen hasn't been converted
/// yet. Every screen in Step 3 navigates here until its target exists.
class PlaceholderScreen extends StatelessWidget {
  final String routeName;

  const PlaceholderScreen({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Coming soon', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(routeName, style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}
