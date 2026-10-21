import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/application.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/relative_time.dart';
import '../../widgets/app_page.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/badges.dart';
import '../../widgets/company_mark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// Recovery screen for applications swipe-deleted from the Applications
/// tab — the SnackBar undo shown right after a swipe only lasts a few
/// seconds; this is the longer-lived backstop for realizing later.
class RecentlyDeletedApplicationsScreen extends StatefulWidget {
  const RecentlyDeletedApplicationsScreen({super.key});

  @override
  State<RecentlyDeletedApplicationsScreen> createState() => _RecentlyDeletedApplicationsScreenState();
}

class _RecentlyDeletedApplicationsScreenState extends State<RecentlyDeletedApplicationsScreen> {
  List<Application> _apps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await context.read<Repositories>().applications.listRecentlyDeleted();
    if (mounted) setState(() => _apps = apps);
  }

  Future<void> _restore(Application a) async {
    await context.read<Repositories>().applications.restoreApplication(a.id);
    await _load();
    if (!mounted) return;
    // Kept-alive tabs (Home's Applied badges, the Applications tab) re-read
    // from listApplications() on a dataVersion bump — without this a
    // restored application's job stays showing "Apply" on a backgrounded
    // feed.
    context.read<AppState>().bumpDataVersion();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Restored ${a.opportunity.title} — check Applications')));
  }

  Future<void> _confirmDeleteForever(Application a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Delete forever?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold)),
        content: Text(
          "This application will be permanently removed and can't be recovered.",
          style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: AppFontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<Repositories>().applications.permanentlyDelete(a.id);
      await _load();
      if (!mounted) return;
      context.read<AppState>().bumpDataVersion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      return AppPage(
        backLabel: 'Profile',
        backFallback: '/tabs/profile',
        title: 'Recently deleted',
        subtitle: '${_apps.length} deleted application${_apps.length != 1 ? 's' : ''}',
        body: _apps.isEmpty
            ? const Padding(padding: EdgeInsets.only(top: AppSpacing.xxl), child: EmptyState(icon: Ionicons.trash_outline, title: 'Nothing here', subtitle: 'Applications you swipe-delete will show up here so you can restore them.'))
            : AppGrid(columns: 2, children: [for (final a in _apps) _DeletedApplicationCard(app: a, onRestore: () => _restore(a), onDeleteForever: () => _confirmDeleteForever(a))]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, 0),
            child: const BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/profile'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recently deleted', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    '${_apps.length} deleted application${_apps.length != 1 ? 's' : ''}',
                    textAlign: TextAlign.left,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _apps.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                        child: const EmptyState(
                          icon: Ionicons.trash_outline,
                          title: 'Nothing here',
                          subtitle: 'Applications you swipe-delete will show up here so you can restore them.',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxl),
                    children: _apps
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _DeletedApplicationCard(
                                app: a,
                                onRestore: () => _restore(a),
                                onDeleteForever: () => _confirmDeleteForever(a),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      )),
    );
  }
}

class _DeletedApplicationCard extends StatelessWidget {
  final Application app;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;
  const _DeletedApplicationCard({required this.app, required this.onRestore, required this.onDeleteForever});

  @override
  Widget build(BuildContext context) {
    final a = app;
    final deletedAt = DateTime.tryParse(a.deletedAt ?? '') ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        boxShadow: AppBreakpoints.isWide(context) ? null : AppShadows.card,
        border: AppBreakpoints.isWide(context) ? Border.all(color: AppColors.border) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyMark(company: a.opportunity.company, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.opportunity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(a.opportunity.company, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: a.status),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text('Deleted ${relativeTimeLabel(deletedAt)}', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            padding: const EdgeInsets.only(top: AppSpacing.md),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: Row(
              children: [
                Expanded(
                  child: PillButton(label: 'Restore', icon: Ionicons.refresh_outline, compact: true, onPressed: onRestore),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PillButton(label: 'Delete', variant: PillVariant.ghost, icon: Ionicons.trash_outline, compact: true, onPressed: onDeleteForever),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
