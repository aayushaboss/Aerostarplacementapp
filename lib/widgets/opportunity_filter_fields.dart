import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../mockData/mock_profile_options.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'app_chip.dart';
import 'autocomplete_field.dart';
import 'field_label.dart';

const oppFilterGoalOptions = [
  ('internship', 'Internship'),
  ('job', 'Full-time'),
  ('both', 'Both'),
];

// Opportunity.workMode's real values — an earlier version of this facet
// (JobPreferences.shift) used a different, mismatched WFH/Hybrid/On-site
// vocabulary that matched nothing on an actual Opportunity.
const oppFilterWorkModeOptions = ['Remote', 'Onsite', 'Hybrid'];

const oppFilterEmploymentTypeOptions = ['Full-time', 'Part-time'];

/// The 5 filter sections shared by `OpportunityFilterScreen` (mobile, a
/// full-screen push) and `college_feed_screen.dart`'s desktop filter panel
/// (a persistent sidebar panel, live-committing on every change). Purely
/// presentational — parameterized by current values + callbacks, no state
/// of its own, so each host owns its own commit semantics (buffered +
/// explicit Apply on mobile, immediate on desktop).
class OpportunityFilterFields extends StatelessWidget {
  final List<String> roles;
  final String goal;
  final String? workMode;
  final String? employmentType;
  final List<String> cities;
  final VoidCallback onPickRoles;
  final ValueChanged<String> onSelectGoal;
  final ValueChanged<String> onToggleWorkMode;
  final ValueChanged<String> onToggleEmploymentType;
  final ValueChanged<String> onAddCity;
  final ValueChanged<String> onRemoveCity;
  // Desktop-only — an inline checkbox list (every category visible, one
  // tap each) instead of the mobile "tap to open a picker screen" row.
  // Pushing a whole new screen just to toggle a checkbox is a mobile
  // pattern; a persistent sidebar has room to just show the list, matching
  // how a standard desktop filter sidebar (e.g. the reference site's own
  // Category filter) actually works. [onToggleRole] is required when this
  // is true; [onPickRoles] is simply unused in that case.
  final bool categoryAsChecklist;
  final ValueChanged<String>? onToggleRole;

  /// Smaller chips, for the narrow filter panel beside a list.
  final bool dense;

  const OpportunityFilterFields({
    super.key,
    required this.roles,
    required this.goal,
    required this.workMode,
    required this.employmentType,
    required this.cities,
    required this.onPickRoles,
    required this.onSelectGoal,
    required this.onToggleWorkMode,
    required this.onToggleEmploymentType,
    required this.onAddCity,
    required this.onRemoveCity,
    this.categoryAsChecklist = false,
    this.onToggleRole,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final employmentDisabled = goal == 'internship';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Category', tight: true),
        if (categoryAsChecklist)
          _CategoryChecklist(selected: roles, onToggle: onToggleRole!)
        else
          GestureDetector(
            onTap: onPickRoles,
            // No wrapping pill/background here — a single oversized rounded
            // shape around a whole cluster of badges read as a giant, oddly
            // shaped badge of its own. Kept as plain as "Preferred cities"
            // below: just the badges (or the placeholder), with a trailing
            // chevron as the only signal this row opens the picker.
            child: Row(
              // Top-aligned, not centered — with several badges wrapping onto
              // 2-3 lines, a vertically-centered chevron drifts down next to
              // the middle row instead of reading as "this whole block is
              // tappable, here's the arrow."
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: roles.isEmpty
                      ? Text('All roles', style: AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.gray400, fontWeight: AppFontWeight.regular))
                      : Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: roles.map(_roleBadge).toList(),
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                ),
              ],
            ),
          ),
        const FieldLabel('Internship or full-time'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: oppFilterGoalOptions
              .map((g) => AppChip(label: g.$2, selected: goal == g.$1, dense: dense, onPressed: () => onSelectGoal(g.$1)))
              .toList(),
        ),
        const FieldLabel('Work mode'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: oppFilterWorkModeOptions
              .map((m) => AppChip(label: m, selected: workMode == m, dense: dense, onPressed: () => onToggleWorkMode(m)))
              .toList(),
        ),
        const FieldLabel('Employment type'),
        if (employmentDisabled)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Only applies to full-time roles.',
              style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12),
            ),
          ),
        Opacity(
          opacity: employmentDisabled ? 0.4 : 1.0,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: oppFilterEmploymentTypeOptions
                .map((t) => AppChip(
                      label: t,
                      selected: employmentType == t,
                      disabled: employmentDisabled,
                      dense: dense,
                      onPressed: () => onToggleEmploymentType(t),
                    ))
                .toList(),
          ),
        ),
        const FieldLabel('Preferred cities'),
        if (cities.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: cities.map((c) => _removableChip(c, () => onRemoveCity(c))).toList(),
          ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AutocompleteField(
            value: '',
            placeholder: 'e.g. Bengaluru',
            icon: Ionicons.location_outline,
            options: mockCities,
            onChanged: (_) {},
            onSelected: onAddCity,
            onSubmitted: onAddCity,
          ),
        ),
      ],
    );
  }

  Widget _removableChip(String label, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Ionicons.close, size: 14, color: AppColors.blue),
          ],
        ),
      ),
    );
  }

  // Same visual language as _removableChip, minus the close icon — Category
  // is only ever edited wholesale via the picker screen (onPickRoles), not
  // added/removed inline the way cities are, so a badge here is read-only;
  // the whole row it sits in already opens that picker on tap.
  Widget _roleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
    );
  }
}

/// Desktop sidebar's inline Category filter — every option visible at
/// once with a checkbox, no picker screen to open. Mirrors the reference
/// site's own desktop filter sidebar exactly (a plain checkbox list, not
/// chips), which is the pattern a persistent sidebar has room for.
class _CategoryChecklist extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;
  const _CategoryChecklist({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final role in mockAllRoles) _row(role),
      ],
    );
  }

  Widget _row(String role) {
    final checked = selected.contains(role);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        checked: checked,
        label: role,
        child: GestureDetector(
          onTap: () => onToggle(role),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: checked ? AppColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: checked ? AppColors.blue : AppColors.gray200, width: 1.5),
                ),
                child: checked ? const Icon(Ionicons.checkmark, size: 13, color: AppColors.white) : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  role,
                  style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.regular),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
