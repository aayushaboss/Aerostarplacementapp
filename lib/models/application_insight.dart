import 'package:flutter/material.dart';

/// One slice of a donut chart — a labelled share of the whole, optionally
/// marking the slice that represents the viewing user ("You").
class InsightSegment {
  final String label;
  final double percent;
  final bool isYou;
  final Color color;

  const InsightSegment({required this.label, required this.percent, required this.color, this.isYou = false});
}

/// One "how you compare" card — mirrors Naukri's post-apply insights strip
/// (Work Experience / Industry / Location / Department / Key skills / Early
/// Applicant), each a donut broken into [segments] plus whether this
/// specific criterion is one the application already satisfies.
class ApplicationInsight {
  final String title;
  final IconData icon;
  final bool matched;
  final List<InsightSegment> segments;

  /// Present only for the two "single headline stat" cards (Early
  /// Applicants, Key skills) — shown instead of a segment-by-segment
  /// legend, since there's one number worth calling out rather than a
  /// breakdown.
  final String? description;

  const ApplicationInsight({
    required this.title,
    required this.icon,
    required this.matched,
    required this.segments,
    this.description,
  });
}
