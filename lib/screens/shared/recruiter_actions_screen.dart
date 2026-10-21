import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_profile_activity.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/relative_time.dart';
import '../../widgets/app_page.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/responsive_body.dart';

const _actionIcons = {
  'Viewed your profile': Ionicons.eye_outline,
  'Downloaded your resume': Ionicons.download_outline,
  'Shortlisted you': Ionicons.star_outline,
  'Saved your profile': Ionicons.bookmark_outline,
};

/// Naukri's "Recruiter Actions" — a company-attributed activity feed
/// ("Microsoft viewed your profile"), not just a bare count. The Home
/// dashboard's "Recruiter actions" card used to open the generic
/// Notifications feed, which has no recruiter-specific content — this is
/// the real destination.
class RecruiterActionsScreen extends StatelessWidget {
  const RecruiterActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final actions = recruiterActionsFor(user);
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return AppPage(
        backLabel: 'Profile',
        backFallback: '/tabs/profile',
        title: 'Recruiter actions',
        subtitle: 'What recruiters have done with your profile, most recent first.',
        maxWidth: 760,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.warningA15, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Ionicons.alert_circle_outline, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Sample data — this will reflect your real activity once recruiter analytics are live.', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontSize: 12, fontWeight: AppFontWeight.medium, height: 1.3))),
            ],
          ),
        ),
            const SizedBox(height: AppSpacing.lg),
            for (final a in actions)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle), child: Icon(_actionIcons[a.action] ?? Ionicons.business_outline, size: 18, color: AppColors.blue)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.company, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
                          Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(a.action, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12))),
                        ],
                      ),
                    ),
                    Text(relativeTimeLabel(a.at), style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        children: [
          const PageHeaderBar(title: 'Recruiter actions'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                // This whole screen is currently synthetic, seeded on the
                // user's own identifier so it looks like consistent real
                // history — without this, a student has no way to tell
                // "Microsoft shortlisted you" apart from a genuine event.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.warningA15, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Ionicons.alert_circle_outline, size: 18, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Sample data — this will reflect your real activity once recruiter analytics are live.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontSize: 12, fontWeight: AppFontWeight.medium, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  noOrphan("What recruiters have done with your profile — most recent first."),
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...actions.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                            child: Icon(_actionIcons[a.action] ?? Ionicons.business_outline, size: 18, color: AppColors.gray500),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.company, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                                  child: Text(a.action, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          Text(relativeTimeLabel(a.at), style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
