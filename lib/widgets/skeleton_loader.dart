import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';

/// A single shimmering placeholder block — the primitive every shape below
/// is composed from, the same way this app already composes small
/// primitives into larger shells elsewhere (e.g. `_MetaLine` reused across
/// card widgets). Only existing gray/offWhite tokens — no new colors.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({super.key, required this.width, required this.height, this.borderRadius = AppRadius.sm});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sweeps a lighter band across the block, left to right, looping —
        // a plain gradient shift rather than a package dependency.
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 3, 0),
              end: Alignment(0 + t * 3, 0),
              colors: const [AppColors.gray100, AppColors.gray200, AppColors.gray100],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder matching [OpportunityCarouselCard]'s silhouette — icon-circle
/// + two text bars + meta lines — for skeletonizing a horizontal carousel
/// while its content loads.
class SkeletonCarouselCard extends StatelessWidget {
  const SkeletonCarouselCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      // Matches OpportunityCarouselCard's own fixed height exactly (see
      // that widget's comment on why it's fixed, not intrinsic).
      height: 290,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 44, height: 44, borderRadius: AppRadius.md),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: double.infinity, height: 15),
                    const SizedBox(height: AppSpacing.xs),
                    SkeletonBox(width: MediaQuery.sizeOf(context).width * 0.2, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.border),
          ),
          const SkeletonBox(width: 120, height: 12),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 90, height: 12),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: SkeletonBox(width: double.infinity, height: 36, borderRadius: AppRadius.pill),
          ),
        ],
      ),
    );
  }
}

/// Placeholder matching a match-card's silhouette (rank badge + title +
/// percent bar) — used for the aptitude Results screen while matches load.
class SkeletonMatchRow extends StatelessWidget {
  const SkeletonMatchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, borderRadius: AppRadius.pill),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: MediaQuery.sizeOf(context).width * 0.35, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
