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
import '../../widgets/app_page.dart';
import '../../widgets/badges.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/responsive_body.dart';

const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Naukri's "Search Appearances" — a daily trend plus the keywords that
/// actually surfaced this profile, not just a bare count with nowhere to
/// go. The Home dashboard's "Search appearances" card used to open the
/// generic Notifications feed, which has no search-visibility content at
/// all — this is the real destination.
class SearchAppearancesScreen extends StatelessWidget {
  const SearchAppearancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final appearances = searchAppearancesFor(user);
    final keywords = searchKeywordsFor(user);
    final total = appearances.fold<int>(0, (a, b) => a + b.count);
    final maxCount = appearances.map((a) => a.count).fold<int>(1, (a, b) => a > b ? a : b);
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      final expanded = AppBreakpoints.isExpanded(context);
      final chartCard = Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearances', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                    Text('$total', style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 32, fontWeight: AppFontWeight.semibold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('Last 14 days', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SearchTrendChart(appearances: appearances, maxCount: maxCount),
          ],
        ),
      );
      final keywordsCard = Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What recruiters searched', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold)),
            Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(noOrphan('Search phrases that likely surfaced your profile, based on your roles and skills.'), style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12))),
            Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: keywords.map((k) => AppTag(label: k)).toList())),
          ],
        ),
      );
      final banner = Container(
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
        );
      return AppPage(
        backLabel: 'Profile',
        backFallback: '/tabs/profile',
        title: 'Search appearances',
        subtitle: 'How often recruiters found you in search.',
        scroll: !expanded,
        body: expanded
            ? TwoPane(main: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [banner, const SizedBox(height: AppSpacing.lg), chartCard]), side: keywordsCard, sideWidth: 380)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [banner, const SizedBox(height: AppSpacing.lg), chartCard, const SizedBox(height: AppSpacing.lg), keywordsCard]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        children: [
          const PageHeaderBar(title: 'Search appearances'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                // Same disclaimer as recruiter_actions_screen.dart — this
                // trend and these keywords are synthetic, seeded on the
                // user's own identifier so they look like consistent real
                // history with no other signal that they aren't.
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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Appearances', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                              Text('$total', style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 32, fontWeight: AppFontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Text('Last 14 days', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SearchTrendChart(appearances: appearances, maxCount: maxCount),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
                  child: Text('What recruiters searched', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.bold)),
                ),
                Text(
                  noOrphan('Search phrases that likely surfaced your profile, based on your roles and skills.'),
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: keywords.map((k) => AppTag(label: k)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

/// A proper trend chart, not a bare row of bars: a callout on the peak day,
/// pill-topped bars on a shared baseline, and date ticks on the axis — the
/// cues that make a chart read as "real data" instead of decoration.
class _SearchTrendChart extends StatelessWidget {
  final List<SearchAppearance> appearances;
  final int maxCount;
  const _SearchTrendChart({required this.appearances, required this.maxCount});

  static const _barAreaHeight = 84.0;
  static const _calloutHeight = 22.0;

  @override
  Widget build(BuildContext context) {
    final peakIndex = () {
      var best = 0;
      for (var i = 1; i < appearances.length; i++) {
        if (appearances[i].count > appearances[best].count) best = i;
      }
      return best;
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _calloutHeight + _barAreaHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: appearances.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              final isPeak = i == peakIndex && a.count > 0;
              final barHeight = a.count == 0 ? 3.0 : 10 + (a.count / maxCount) * (_barAreaHeight - 10);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Tooltip(
                    message: '${a.count} on ${a.date.day} ${_monthShort[a.date.month - 1]}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: _calloutHeight,
                          child: isPeak
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                  child: Text('${a.count}', style: AppTextStyles.caption.copyWith(color: AppColors.white, fontSize: 12, fontWeight: AppFontWeight.bold)),
                                )
                              : null,
                        ),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: a.count == 0 ? AppColors.gray100 : (isPeak ? AppColors.blue : AppColors.gray200),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(height: 1.5, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: appearances.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              // Every 3rd tick only — labeling all 14 would collide on a
              // phone-width chart.
              final showLabel = i % 3 == 0 || i == appearances.length - 1;
              return Expanded(
                child: Text(
                  showLabel ? '${a.date.day}' : '',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
