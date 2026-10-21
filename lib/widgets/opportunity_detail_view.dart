import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/course.dart';
import '../models/opportunity.dart';
import '../models/opportunity_match.dart';
import '../models/user.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'app_page.dart';
import 'badges.dart';
import 'company_mark.dart';
import 'pill_button.dart';

/// What a job detail needs, whether it is shown as a page, in a stacked column or in the list's
/// detail pane. One place so the three layouts always show the same information.
class OpportunityDetailData {
  final Opportunity opportunity;
  final List<Course> prepCourses;
  final List<Opportunity> similar;
  final User? user;
  final bool applied;
  final bool saved;
  final VoidCallback onApply;
  final VoidCallback onToggleSave;
  final VoidCallback onAskExpert;
  final ValueChanged<Opportunity> onOpenSimilar;
  final ValueChanged<Course> onOpenCourse;
  final VoidCallback? onViewAllSimilar;

  const OpportunityDetailData({
    required this.opportunity,
    required this.prepCourses,
    required this.similar,
    required this.user,
    required this.applied,
    required this.saved,
    required this.onApply,
    required this.onToggleSave,
    required this.onAskExpert,
    required this.onOpenSimilar,
    required this.onOpenCourse,
    this.onViewAllSimilar,
  });

  Opportunity get o => opportunity;

  /// The icon + text rows shown beside the role: city, sector, pay, duration, experience...
  List<(IconData, String)> get metaRows => [
        (Ionicons.location_outline, o.location),
        if (o.sector.isNotEmpty) (Ionicons.business_outline, o.sector),
        (Ionicons.cash_outline, o.stipend),
        if (o.internStipend != null && o.salaryRange.isNotEmpty) (Ionicons.cash_outline, o.salaryRange),
        (Ionicons.time_outline, o.duration),
        if (o.experience.isNotEmpty) (Ionicons.briefcase_outline, 'Experience: ${o.experience}'),
        if (o.department.isNotEmpty) (Ionicons.layers_outline, o.department),
        if (o.startupId.isNotEmpty) (Ionicons.finger_print_outline, 'Startup ID: ${o.startupId}  ·  Job ID: ${o.id}'),
      ];

  String? get matchLabel => applied ? null : o.matchLabelFor(user);
}

Widget _tagRow(Opportunity o) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppTag(label: o.type),
        if (o.experience.isNotEmpty) AppTag(label: o.experience),
        if (o.demoOpening) const AppTag(label: 'Demo opening'),
      ],
    );

Widget _appliedCount(Opportunity o) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Ionicons.people_outline, size: 14, color: AppColors.gray500),
        const SizedBox(width: AppSpacing.xs),
        Text('${o.applicantCount} people applied', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
      ],
    );

Widget _metaItem(IconData icon, String label, {double iconSize = 16}) => Row(
      children: [
        Icon(icon, size: iconSize, color: AppColors.gray500),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium))),
      ],
    );

Widget _h3(String text) => Text(text, style: AppTextStyles.h3.copyWith(color: AppColors.ink));

Widget _requirement(String text, {double fontSize = 13}) => Row(
      children: [
        Container(width: 24, height: 24, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle), child: const Icon(Ionicons.checkmark, size: 13, color: AppColors.blue)),
        const SizedBox(width: AppSpacing.md - 4),
        Expanded(child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: fontSize))),
      ],
    );

Widget _roundIconButton(IconData icon, String label, VoidCallback onTap, {bool active = false}) => Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: active ? AppColors.ink : AppColors.gray500),
          ),
        ),
      ),
    );

/// A job in the "Similar roles" grid: type, title, company, city.
class SimilarRoleCard extends StatelessWidget {
  final Opportunity o;
  final VoidCallback onTap;
  const SimilarRoleCard({super.key, required this.o, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTag(label: o.type, compact: true),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.md - 4), child: Text(o.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold))),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(o.company, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(children: [const Icon(Ionicons.location_outline, size: 13, color: AppColors.gray500), const SizedBox(width: AppSpacing.xs), Flexible(child: Text(o.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)))]),
          ),
        ],
      ),
    );
  }
}

/// A "Prep for this role" row: gray tint card (no shadow), course icon, title, duration.
class PrepCourseTile extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  const PrepCourseTile({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: TintCard(
          child: Row(
            children: [
              Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md)), child: const Icon(Ionicons.book_outline, size: 18, color: AppColors.ink)),
              const SizedBox(width: AppSpacing.md - 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                    Text('${course.duration} • ${course.modules} modules', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

/// The main column of the expanded detail page: role header, tags, about, requirements, similar
/// roles (3 across) and prep courses (2 across).
class OpportunityDetailMain extends StatelessWidget {
  final OpportunityDetailData data;
  final int similarColumns;
  const OpportunityDetailMain({super.key, required this.data, this.similarColumns = 3});

  @override
  Widget build(BuildContext context) {
    final o = data.o;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CompanyMark(company: o.company, size: 72),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.title, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                  Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(o.company, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold))),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppTag(label: o.type),
              if (o.experience.isNotEmpty) AppTag(label: o.experience),
              if (o.demoOpening) const AppTag(label: 'Demo opening'),
              if (o.applicantCount > 0) Padding(padding: const EdgeInsets.only(left: AppSpacing.sm), child: _appliedCount(o)),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: Divider(height: 1, color: AppColors.border)),
        _h3('About the role'),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md - 4),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: Text(o.about, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, height: 22 / 14))),
        ),
        if (o.requirements.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: _h3('Requirements')),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: LayoutBuilder(
              builder: (context, box) {
                final cols = box.maxWidth >= 480 ? 2 : 1;
                return Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.md - 4,
                  children: [for (final r in o.requirements) SizedBox(width: (box.maxWidth - (cols - 1) * AppSpacing.lg) / cols, child: _requirement(r))],
                );
              },
            ),
          ),
        ],
        if (data.similar.isNotEmpty) ...[
          SectionHeading(title: 'Similar roles', padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md), onViewAll: data.onViewAllSimilar),
          AppGrid(columns: similarColumns, gap: AppSpacing.md, children: [for (final s in data.similar.take(similarColumns)) SimilarRoleCard(o: s, onTap: () => data.onOpenSimilar(s))]),
        ],
        if (data.prepCourses.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md), child: _h3('Prep for this role')),
          AppGrid(columns: 2, gap: AppSpacing.md, children: [for (final c in data.prepCourses.take(4)) PrepCourseTile(course: c, onTap: () => data.onOpenCourse(c))]),
        ],
      ],
    );
  }
}

/// The right-hand card of the expanded detail page: meta rows, match and deadline, Apply Now,
/// Save and Ask expert. Stays in view while the main column scrolls.
class OpportunityDetailSideCard extends StatelessWidget {
  final OpportunityDetailData data;
  const OpportunityDetailSideCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final o = data.o;
    final deadline = data.applied ? null : o.deadlineLabel;
    return SurfaceCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (icon, label) in data.metaRows) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md - 4), child: _metaItem(icon, label)),
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(height: 1, color: AppColors.border)),
          if (data.matchLabel != null || deadline != null)
            Row(
              children: [
                if (data.matchLabel != null) ...[const Icon(Ionicons.star, size: 13, color: AppColors.ink), const SizedBox(width: AppSpacing.xs), Text(data.matchLabel!, style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium))],
                if (data.matchLabel != null && deadline != null) Text(' · ', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                if (deadline != null) Text(deadline, style: AppTextStyles.caption.copyWith(color: o.deadlineIsUrgent ? AppColors.error : AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: PillButton(label: data.applied ? 'Applied' : 'Apply Now', icon: data.applied ? Ionicons.checkmark_circle : null, onPressed: data.onApply, disabled: data.applied),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md - 4),
            child: Row(
              children: [
                Expanded(child: _SideAction(icon: data.saved ? Ionicons.bookmark : Ionicons.bookmark_outline, label: data.saved ? 'Saved' : 'Save', onTap: data.onToggleSave)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _SideAction(icon: Ionicons.chatbubble_outline, label: 'Ask expert', onTap: data.onAskExpert)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SideAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, size: 16, color: AppColors.ink), const SizedBox(width: 6), Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.medium))],
          ),
        ),
      ),
    );
  }
}

/// The medium-window detail: one column (the rail is already beside it) with the meta in a gray
/// tint card and a bar under it for Apply. Returns the scrolling content and the bottom bar
/// separately so the page can pin the bar.
class OpportunityDetailStacked extends StatelessWidget {
  final OpportunityDetailData data;
  const OpportunityDetailStacked({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final o = data.o;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CompanyMark(company: o.company, size: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.title, style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 20)),
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(o.company, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold))),
                ],
              ),
            ),
          ],
        ),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: _tagRow(o)),
        if (o.applicantCount > 0) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: _appliedCount(o)),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: TintCard(
            padding: const EdgeInsets.all(AppSpacing.md + 4),
            child: LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.md - 4,
                children: [for (final (icon, label) in data.metaRows) SizedBox(width: (box.maxWidth - AppSpacing.lg) / 2, child: _metaItem(icon, label))],
              ),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: _h3('About the role')),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.md - 4), child: Text(o.about, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13, height: 20 / 13))),
        if (o.requirements.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: _h3('Requirements')),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.md - 4), child: Column(children: [for (final r in o.requirements) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _requirement(r))])),
        ],
        if (data.similar.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md), child: _h3('Similar roles')),
          AppGrid(columns: 2, gap: AppSpacing.md, children: [for (final s in data.similar.take(2)) SimilarRoleCard(o: s, onTap: () => data.onOpenSimilar(s))]),
        ],
        if (data.prepCourses.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md), child: _h3('Prep for this role')),
          Column(children: [for (final c in data.prepCourses.take(3)) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: PrepCourseTile(course: c, onTap: () => data.onOpenCourse(c)))]),
        ],
      ],
    );
  }
}

/// The bar under the medium-window detail: pay and match on the left, Apply Now on the right.
class OpportunityApplyBar extends StatelessWidget {
  final OpportunityDetailData data;
  const OpportunityApplyBar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final o = data.o;
    final parts = [if (data.matchLabel != null) data.matchLabel!, if (!data.applied && o.deadlineLabel != null) o.deadlineLabel!];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(o.stipend, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                if (parts.isNotEmpty) Text(parts.join(' · '), style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 240, child: PillButton(label: data.applied ? 'Applied' : 'Apply Now', icon: data.applied ? Ionicons.checkmark_circle : null, onPressed: data.onApply, disabled: data.applied)),
        ],
      ),
    );
  }
}

/// The detail shown beside the list on an expanded window: header with Save and "open full page",
/// tags, Apply Now, meta, about and requirements.
class OpportunityDetailPane extends StatelessWidget {
  final OpportunityDetailData data;
  final VoidCallback onOpenFull;
  const OpportunityDetailPane({super.key, required this.data, required this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    final o = data.o;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyMark(company: o.company, size: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title, style: AppTextStyles.h2.copyWith(color: AppColors.ink)),
                    Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(o.company, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold))),
                  ],
                ),
              ),
              _roundIconButton(data.saved ? Ionicons.bookmark : Ionicons.bookmark_outline, data.saved ? 'Remove from saved' : 'Save', data.onToggleSave, active: data.saved),
              const SizedBox(width: AppSpacing.sm),
              _roundIconButton(Ionicons.open_outline, 'Open full page', onOpenFull),
            ],
          ),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: _tagRow(o)),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg - 4),
            child: Row(
              children: [
                PillButton(label: data.applied ? 'Applied' : 'Apply Now', icon: data.applied ? Ionicons.checkmark_circle : null, full: false, onPressed: data.onApply, disabled: data.applied),
                const SizedBox(width: AppSpacing.md - 4),
                if (o.applicantCount > 0) _appliedCount(o),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.lg),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg - 4),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border), bottom: BorderSide(color: AppColors.border))),
            child: LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.md - 4,
                children: [for (final (icon, label) in data.metaRows) SizedBox(width: (box.maxWidth - AppSpacing.lg) / 2, child: _metaItem(icon, label))],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: _h3('About the role')),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.md - 4), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: Text(o.about, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13, height: 20 / 13)))),
          if (o.requirements.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: _h3('Requirements')),
            Padding(padding: const EdgeInsets.only(top: AppSpacing.md - 4), child: Column(children: [for (final r in o.requirements) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _requirement(r))])),
          ],
        ],
      ),
    );
  }
}
