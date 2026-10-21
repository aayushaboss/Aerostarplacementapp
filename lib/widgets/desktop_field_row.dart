import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Places two form field groups (each already its own FieldLabel + input,
/// unchanged) side by side at desktop widths — same-shaped fields only (a
/// fixed-height text input next to a variable-height chip Wrap reads
/// visually uneven, so those stay full-width instead of paired here; see
/// the pairing table in micro_profile_screen.dart/profile_edit_screen.dart).
class DesktopFieldRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DesktopFieldRow({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.xl),
        Expanded(child: right),
      ],
    );
  }
}
