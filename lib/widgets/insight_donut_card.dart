import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/application_insight.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Fixed-width card in the "how this application compares" carousel — a
/// ring chart (icon centered) plus either a single headline stat +
/// description (Key Skills, Early Applicant) or a per-segment legend
/// (Work Experience, Location, Department, Industry). Naukri's own version
/// of this pairs the donut with exactly these two layouts.
class InsightDonutCard extends StatelessWidget {
  final ApplicationInsight insight;
  const InsightDonutCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final youSegment = insight.segments.firstWhere((s) => s.isYou, orElse: () => insight.segments.first);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // No matched/unmatched badge here — the checklist card above this
          // carousel already shows a checkmark/✕ for this exact title; the
          // donut's own segment color carries the same signal without
          // repeating the icon.
          Text(
            insight.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CustomPaint(
                  painter: _DonutPainter(segments: insight.segments),
                  child: Center(
                    child: Icon(insight.icon, size: 22, color: AppColors.gray500),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: insight.description != null
                    ? _StatSummary(percent: youSegment.percent, description: insight.description!)
                    : _Legend(segments: insight.segments),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatSummary extends StatelessWidget {
  final double percent;
  final String description;
  const _StatSummary({required this.percent, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${percent.round()}%',
          style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: AppFontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final List<InsightSegment> segments;
  const _Legend({required this.segments});

  @override
  Widget build(BuildContext context) {
    // Biggest share first — the interesting slice usually isn't "Other".
    final sorted = List.of(segments)..sort((a, b) => b.percent.compareTo(a.percent));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: sorted.take(3).map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      '${s.label}: ${s.percent.round()}%',
                      style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium),
                    ),
                    if (s.isYou)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(4)),
                        child: Text('You', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<InsightSegment> segments;
  const _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final total = segments.fold<double>(0, (a, s) => a + s.percent);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s.percent / total) * 2 * math.pi;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      // A hairline gap between slices keeps them visually distinct instead
      // of reading as one blurred ring, without needing rounded caps to do
      // it (which would distort thin slices).
      final gap = segments.length > 1 ? 0.035 : 0.0;
      canvas.drawArc(rect, start + gap, (sweep - gap * 2).clamp(0, sweep), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments;
}
