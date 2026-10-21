import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'pill_button.dart';
import './adaptive_sheet.dart';

/// A field styled identically to PillInput at rest, but tapping it opens a
/// wheel-picker sheet instead of the keyboard — for month/year and year
/// values, where scrolling a wheel to the right answer is faster and less
/// ambiguous than typing free text into a bare box.
class DatePickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final IconData? icon;
  final VoidCallback onTap;
  // Dims the field and makes it inert — e.g. an End-date field before its
  // own Start date has a value, where the picker's own bounds have nothing
  // to floor against yet.
  final bool disabled;

  const DatePickerField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.icon,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          height: 54,
          // lg, not xl: two of these sit side by side (Start / End date) and
          // xl padding left ~36px for text, so "Start date" wrapped to two rows.
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.gray500),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                // Single line, shrinking slightly rather than wrapping.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value ?? placeholder,
                    maxLines: 1,
                    softWrap: false,
                    style: value == null
                        ? AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.gray400, fontWeight: AppFontWeight.regular)
                        : AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.ink),
                  ),
                ),
              ),
              const Icon(Ionicons.chevron_down, size: 16, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sheetHandle() => Center(
      child: Container(
        width: AppSpacing.xxl,
        height: AppSpacing.xs,
        decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
    );

Widget _sheetTitle(String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
    );

/// Bottom sheet with a Month/Year wheel — for fields like a job's joining
/// date, or a work-experience start/end date, where no one needs to pick a
/// specific *day*. Matches the sheet chrome already established by
/// _showPrepSheet (applications_tracker_screen.dart) elsewhere in the app:
/// drag handle, title, then content, then one action. [minYear]/[maxYear]
/// default to the original hardcoded bounds (40 years back, up to the
/// current year) — pass [minYear] to floor an end-date picker at a
/// previously-picked start date, same idea as showYearPickerSheet's own
/// minYear param.
Future<DateTime?> showMonthYearPickerSheet(
  BuildContext context, {
  DateTime? initialDate,
  String title = 'Joining date',
  int? minYear,
  int? maxYear,
  // Month-granular bounds, on top of minYear/maxYear's year-only ones —
  // CupertinoDatePicker's minimumYear/maximumYear alone leave every month
  // within the bound year selectable, future ones included. Both default
  // to null (unbounded), so this is backward-compatible for any caller
  // that only ever needed year-level bounds.
  DateTime? minDate,
  DateTime? maxDate,
}) {
  var current = initialDate ?? DateTime.now();
  // Clamp defensively rather than trust every caller's initialDate is
  // already inside [minDate, maxDate] — CupertinoDatePicker asserts
  // initialDateTime must fall within both when they're set, and a
  // previously-saved date (e.g. opening an existing entry to edit it)
  // could predate this bound existing at all. Clamping once here means no
  // call site can crash on this.
  if (maxDate != null && current.isAfter(maxDate)) current = maxDate;
  if (minDate != null && current.isBefore(minDate)) current = minDate;
  return showAdaptiveSheet<DateTime>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(sheetContext).padding.bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHandle(),
          _sheetTitle(title),
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.monthYear,
              initialDateTime: current,
              minimumYear: minYear ?? DateTime.now().year - 40,
              maximumYear: maxYear ?? DateTime.now().year,
              minimumDate: minDate,
              maximumDate: maxDate,
              onDateTimeChanged: (picked) => current = picked,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: PillButton(label: 'Done', onPressed: () => Navigator.of(sheetContext).pop(current)),
          ),
        ],
      ),
    ),
  );
}

/// Bottom sheet with a single year wheel — for fields like "last used"
/// where the only meaningful value is a calendar year.
Future<int?> showYearPickerSheet(BuildContext context, {required int minYear, required int maxYear, int? initialYear, required String title}) {
  final years = [for (var y = maxYear; y >= minYear; y--) y];
  var index = initialYear != null && years.contains(initialYear) ? years.indexOf(initialYear) : 0;
  return showAdaptiveSheet<int>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(sheetContext).padding.bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHandle(),
          _sheetTitle(title),
          SizedBox(
            height: 216,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(initialItem: index),
              onSelectedItemChanged: (i) => index = i,
              children: years.map((y) => Center(child: Text('$y', style: AppTextStyles.bodyLg.copyWith(fontSize: 18, color: AppColors.ink)))).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: PillButton(label: 'Done', onPressed: () => Navigator.of(sheetContext).pop(years[index])),
          ),
        ],
      ),
    ),
  );
}

/// Bottom sheet with a plain scrollable list of tappable rows — for a set
/// of equally-weighted, clearly-delineated options (e.g. picking a
/// semester) where a spinning wheel doesn't fit as well as it does for a
/// dense numeric range like years/months: every option is legible at once
/// instead of scrolled past. Tapping a row selects and closes immediately
/// (no separate "Done" step), matching the tap-to-select convention
/// already used by this app's other list-style pickers (e.g.
/// language_full_list_screen.dart, course_category_picker_screen.dart).
Future<String?> showOptionListSheet(
  BuildContext context, {
  required List<String> options,
  String? currentValue,
  required String title,
}) {
  return showAdaptiveSheet<String>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(sheetContext).padding.bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHandle(),
          _sheetTitle(title),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              shrinkWrap: true,
              children: options
                  .map((o) => GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(o),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  o,
                                  style: AppTextStyles.bodyLg.copyWith(
                                    fontSize: 16,
                                    color: AppColors.ink,
                                    fontWeight: o == currentValue ? AppFontWeight.semibold : AppFontWeight.regular,
                                  ),
                                ),
                              ),
                              if (o == currentValue) const Icon(Ionicons.checkmark, size: 18, color: AppColors.blue),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}
