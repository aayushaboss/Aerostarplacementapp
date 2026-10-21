import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/skeleton_loader.dart';

/// Dev-only living style guide — renders the app's actual design tokens and
/// shared widgets live (not redrawn approximations), so a designer/engineer
/// can check them against each other in one place (e.g. the restored bold/
/// semibold weight distinction from Round V item 1). Reachable only by
/// typing `/dev/style-guide` in a local debug build — gated behind
/// `kDebugMode` in router.dart so this whole screen compiles out of a
/// release build entirely; no nav-bar link anywhere.
class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        title: const Text('Style Guide', style: TextStyle(color: AppColors.ink)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const _SectionHeading('Colors'),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: const [
              _ColorSwatch('blue', AppColors.blue),
              _ColorSwatch('blueDark', AppColors.blueDark),
              _ColorSwatch('blueDeep', AppColors.blueDeep),
              _ColorSwatch('yellow (brand)', AppColors.brand),
              _ColorSwatch('yellowDark', AppColors.brandPressed),
              _ColorSwatch('white', AppColors.white, border: true),
              _ColorSwatch('offWhite', AppColors.offWhite, border: true),
              _ColorSwatch('gray100', AppColors.gray100),
              _ColorSwatch('gray200', AppColors.gray200),
              _ColorSwatch('gray400', AppColors.gray400),
              _ColorSwatch('gray500', AppColors.gray500),
              _ColorSwatch('ink', AppColors.ink),
              _ColorSwatch('success', AppColors.success),
              _ColorSwatch('warning', AppColors.warning),
              _ColorSwatch('error', AppColors.error),
              _ColorSwatch('border', AppColors.border, border: true),
              _ColorSwatch('focusRing', AppColors.focusRing),
            ],
          ),

          const _SectionHeading('Font weights'),
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'The restored bold/semibold distinction (Round V item 1) — bold '
              'should read visibly heavier than semibold, both heavier than medium/regular.',
              style: TextStyle(fontFamily: kFontFamily, fontSize: 12, color: AppColors.gray500),
            ),
          ),
          const _WeightSample('black (w900)', AppFontWeight.black),
          const _WeightSample('extrabold (w800)', AppFontWeight.extrabold),
          const _WeightSample('bold (w700)', AppFontWeight.bold),
          const _WeightSample('semibold (w600)', AppFontWeight.semibold),
          const _WeightSample('medium (w500)', AppFontWeight.medium),
          const _WeightSample('regular (w400)', AppFontWeight.regular),

          const _SectionHeading('Spacing (AppSpacing)'),
          const _SpacingRow('xs', AppSpacing.xs),
          const _SpacingRow('sm', AppSpacing.sm),
          const _SpacingRow('md', AppSpacing.md),
          const _SpacingRow('lg', AppSpacing.lg),
          const _SpacingRow('xl', AppSpacing.xl),
          const _SpacingRow('xxl', AppSpacing.xxl),
          const _SpacingRow('xxxl', AppSpacing.xxxl),

          const _SectionHeading('Radius (AppRadius)'),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: const [
              _RadiusBox('sm', AppRadius.sm),
              _RadiusBox('md', AppRadius.md),
              _RadiusBox('lg', AppRadius.lg),
              _RadiusBox('xl', AppRadius.xl),
              _RadiusBox('pill', AppRadius.pill),
            ],
          ),

          const _SectionHeading('Shadows (AppShadows)'),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 70,
                  margin: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.lg, bottom: AppSpacing.lg),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                  child: const Text('card', style: TextStyle(fontFamily: kFontFamily, fontSize: 12, color: AppColors.gray500)),
                ),
              ),
              Expanded(
                child: Container(
                  height: 70,
                  margin: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.lg),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                  child: const Text('soft', style: TextStyle(fontFamily: kFontFamily, fontSize: 12, color: AppColors.gray500)),
                ),
              ),
            ],
          ),

          const _SectionHeading('PillButton'),
          const PillButton(label: 'Primary', onPressed: null),
          const SizedBox(height: AppSpacing.sm),
          const PillButton(label: 'Secondary', variant: PillVariant.secondary, onPressed: null),
          const SizedBox(height: AppSpacing.sm),
          const PillButton(label: 'Ghost', variant: PillVariant.ghost, onPressed: null),

          const _SectionHeading('AppChip'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              AppChip(label: 'Unselected', selected: false),
              AppChip(label: 'Selected (solid blue)', selected: true, showCheck: true),
              AppChip(label: 'Dense', dense: true),
            ],
          ),

          const _SectionHeading('AppTag'),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppTag(label: 'Neutral (default)'),
              AppTag(label: 'With icon', icon: Ionicons.ribbon_outline),
              AppTag(label: 'Applied', icon: Ionicons.checkmark_circle),
            ],
          ),

          const _SectionHeading('StatusBadge'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              StatusBadge(status: 'Applied'),
              StatusBadge(status: 'In Review'),
              StatusBadge(status: 'Interview'),
              StatusBadge(status: 'Offer'),
              StatusBadge(status: 'Rejected'),
            ],
          ),

          const _SectionHeading('EmptyState'),
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.lg)),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: const EmptyState(
              icon: Ionicons.bookmark_outline,
              title: 'Nothing here yet',
              subtitle: 'Example subtitle explaining what belongs in this list.',
              buttonLabel: 'Example action',
            ),
          ),

          const _SectionHeading('SkeletonBox'),
          const SkeletonCarouselCard(),
          const SizedBox(height: AppSpacing.md),
          const SkeletonMatchRow(),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
      child: Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final bool border;
  const _ColorSwatch(this.name, this.color, {this.border = false});

  @override
  Widget build(BuildContext context) {
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: border ? Border.all(color: AppColors.border) : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontFamily: kFontFamily, fontSize: 11, fontWeight: AppFontWeight.medium, color: AppColors.ink)),
        Text(hex, style: const TextStyle(fontFamily: kFontFamily, fontSize: 10, color: AppColors.gray500)),
      ],
    );
  }
}

class _WeightSample extends StatelessWidget {
  final String label;
  final FontWeight weight;
  const _WeightSample(this.label, this.weight);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontFamily: kFontFamily, fontSize: 12, color: AppColors.gray500))),
          Text('The quick brown fox', style: TextStyle(fontFamily: kFontFamily, fontSize: 18, fontWeight: weight, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _SpacingRow extends StatelessWidget {
  final String label;
  final double value;
  const _SpacingRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontFamily: kFontFamily, fontSize: 12, color: AppColors.gray500))),
          Container(width: value, height: 16, color: AppColors.gray200),
          const SizedBox(width: AppSpacing.sm),
          Text('${value.toInt()}px', style: const TextStyle(fontFamily: kFontFamily, fontSize: 12, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _RadiusBox extends StatelessWidget {
  final String label;
  final double value;
  const _RadiusBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(value > 40 ? 28 : value)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontFamily: kFontFamily, fontSize: 11, color: AppColors.gray500)),
      ],
    );
  }
}
