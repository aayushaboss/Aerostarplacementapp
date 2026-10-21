import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Single-letter company mark — rune-based (not string-index) so it's safe
/// against any leading surrogate-pair character.
String _companyInitial(String company) {
  final trimmed = company.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

/// Rounded-square letter mark standing in for a company logo — no card
/// anywhere in the app renders a real logo image, so every job/application
/// card uses this same initial instead. Always the app's own brand tint
/// (AppColors.blueA10 / AppColors.blue) — not a per-company color, so it
/// reads as one consistent brand mark rather than a random palette.
class CompanyMark extends StatelessWidget {
  final String company;
  final double size;

  const CompanyMark({super.key, required this.company, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Text(
        _companyInitial(company),
        style: AppTextStyles.h3.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold, fontSize: size * 0.4),
      ),
    );
  }
}
