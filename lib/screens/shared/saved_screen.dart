import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_applications.dart';
import '../../mockData/mock_opportunities.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../models/user.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_page.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/opportunity_meta.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/src/screens/SavedScreen.tsx (SavedScreen).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final items = mockOpportunities.where((o) => appState.isOpportunitySaved(o.id)).toList();
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = AppBreakpoints.isWide(context);
    // Same flat-list-of-uniform-cards shape as Applications — reuse its
    // exact 2-column-at-tablet-width treatment rather than inventing a new
    // reflow rule.
    final columns = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium ? 2 : 1;

    if (isTablet) {
      final cols = AppBreakpoints.gridColumns(context);
      return AppPage(
        backLabel: 'Profile',
        backFallback: '/tabs/profile',
        title: 'Saved',
        subtitle: '${items.length} bookmarked opportunit${items.length == 1 ? 'y' : 'ies'}',
        body: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: EmptyState(icon: Ionicons.bookmark_outline, title: 'Nothing saved yet', subtitle: 'Tap the bookmark on any opportunity to keep it here.', buttonLabel: 'Browse opportunities', onButtonTap: () => context.go('/tabs')))),
              )
            : AppGrid(columns: cols.clamp(2, 3), children: [for (final o in items) _savedRow(context, appState, user, o)]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1200 : 720, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, 0),
            child: BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/profile'),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    noOrphan('${items.length} bookmarked opportunit${items.length == 1 ? 'y' : 'ies'}'),
                    textAlign: TextAlign.left,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                        child: EmptyState(
                          icon: Ionicons.bookmark_outline,
                          title: 'Nothing saved yet',
                          subtitle: 'Tap the bookmark on any opportunity to keep it here.',
                          buttonLabel: 'Browse opportunities',
                          onButtonTap: () => context.go('/tabs'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxl),
                    children: [
                      if (columns == 1)
                        ...List.generate(items.length, (i) {
                          final o = items[i];
                          final row = _savedRow(context, appState, user, o);
                          return i == items.length - 1 ? row : Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: row);
                        })
                      else
                        for (var row = 0; row < (items.length / columns).ceil(); row++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < columns; i++) ...[
                                    if (i > 0) const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: row * columns + i < items.length
                                          ? _savedRow(context, appState, user, items[row * columns + i])
                                          : const SizedBox(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
          ),
        ],
      )),
    );
  }

  Widget _savedRow(BuildContext context, AppState appState, User? user, Opportunity o) {
    return OpportunityRow(
      tag: o.type,
      title: o.title,
      subtitle: o.company,
      meta: opportunityMeta(o),
      matchLabel: o.matchLabelFor(user),
      deadlineLabel: o.deadlineLabel,
      deadlineUrgent: o.deadlineIsUrgent,
      saved: appState.isOpportunitySaved(o.id),
      applied: isOpportunityApplied(o.id),
      onToggleSave: () => appState.toggleSavedOpportunity(o.id),
      onTap: () => context.push('/opportunity/${o.id}'),
      onApply: () => startApplyFlow(context, o, onApplied: () => setState(() {})),
    );
  }
}
