import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Label shown above a form field or field group. Deliberately smaller,
/// lighter-weight, and muted-colored relative to AppTextStyles.body — a
/// label is metadata about the field, not content, and screens that style
/// it identically to the values being entered (bold, ink, same size) make
/// every row compete at the same visual volume, so a form of a dozen
/// fields reads as one undifferentiated wall of "input info input info"
/// instead of a sequence of distinct questions.
///
/// Also owns the gap before it: a full [AppSpacing.xxl] by default, well
/// past the tight [AppSpacing.sm] used between the label and its own
/// field, so unrelated field groups actually read as separate — the
/// previous per-screen convention used the same gap (AppSpacing.lg) both
/// within a group and between groups, which is what flattened the
/// hierarchy in the first place.
class FieldLabel extends StatelessWidget {
  final String text;

  /// Use for the first label in a sequence (e.g. right after a screen's
  /// header or an unrelated block above it) where the full section gap
  /// would double up with spacing that block already provides.
  final bool tight;

  const FieldLabel(this.text, {super.key, this.tight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: tight ? AppSpacing.lg : AppSpacing.xxl, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontSize: 12),
      ),
    );
  }
}
