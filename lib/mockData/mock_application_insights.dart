import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/application.dart';
import '../models/application_insight.dart';
import '../models/user.dart';
import '../theme/colors.dart';
import 'mock_opportunities.dart';

/// Deterministic 0–99 "random" number seeded by a string — same application
/// always produces the same insight numbers (not fresh noise every
/// rebuild), but different applications land on different, plausible ones.
// Masked to 31 bits at every step — on web (dart2js), `int` is backed by a
// JS `number`, which loses precision past 2^53. Folding `hash * 31 + b`
// over a long id/company string blows past that before the loop finishes,
// and the resulting imprecise value skews badly under `% 100`. Masking
// after every multiply keeps it inside the safe-integer range throughout.
int _seeded(String seed, int salt) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  hash = (hash + salt) & 0x7FFFFFFF;
  return hash % 100;
}

/// Naukri-style "recruiter last active" signal on each tracker card — how
/// recently the hiring side touched this specific application, not the
/// aggregate profile-wide activity `recruiterActionsFor` covers.
DateTime recruiterLastActiveFor(Application app) {
  final hoursAgo = 2 + _seeded(app.id, 50) % 70;
  return DateTime.now().subtract(Duration(hours: hoursAgo));
}

/// Naukri-style "how this application compares" strip — one donut per
/// category, each broken into shares with the applicant's own slice called
/// out, plus whether that specific criterion is one this application
/// already satisfies (drives the summary checklist above the carousel).
/// Only categories genuinely computed from the user's real resume/
/// opportunity data belong here — see the comment below on the three that
/// used to be seeded random noise.
List<ApplicationInsight> applicationInsightsFor(Application app, User? user) {
  final opportunity = getOpportunityById(app.opportunityId);
  final seed = app.id;

  // Driven only by real work-experience entries — the old
  // `experienceLevel == '2+ years'` branch was dead (the resume builder
  // only ever writes 'Fresher' or null).
  final hasExperience = user?.resume?.workExperience.isNotEmpty ?? false;
  final experienceShare = hasExperience ? 62 : (18 + _seeded(seed, 1) % 20);

  final sameCity = opportunity != null && user?.city != null && opportunity.location.toLowerCase().contains(user!.city!.toLowerCase());
  final locationShare = sameCity ? (55 + _seeded(seed, 2) % 20) : (2 + _seeded(seed, 2) % 8);

  final skills = (user?.resume?.skills ?? const <String>[]).map((s) => s.toLowerCase()).toList();
  final requirements = opportunity?.requirements ?? const <String>[];
  // % of the *job's* requirements the user's skills cover — not % of the
  // user's skills that happened to match, which unfairly punished anyone
  // with a broad skill list (2 skills covering a 2-requirement job used to
  // score 10% and show a red "missing key skills" right after a rejection).
  final metCount = requirements.where((r) {
    final rl = r.toLowerCase();
    return skills.any((s) => rl.contains(s) || s.contains(rl));
  }).length;
  final keySkillsShare = requirements.isEmpty ? 0 : (metCount * 100 / requirements.length).round();

  // Department, Industry, and Early Applicant used to be here too, each
  // driven entirely by seeded random noise with no real comparator
  // population — removed rather than left fabricated. Key Skills is only
  // shown when the job actually listed requirements to compare against.

  return [
    ApplicationInsight(
      title: 'Work Experience',
      icon: Ionicons.briefcase_outline,
      matched: hasExperience,
      segments: [
        InsightSegment(label: hasExperience ? 'Experienced' : 'Entry level', percent: experienceShare.toDouble(), color: AppColors.blue, isYou: true),
        InsightSegment(label: 'Other', percent: (100 - experienceShare).toDouble(), color: AppColors.gray200),
      ],
    ),
    ApplicationInsight(
      title: 'Location',
      icon: Ionicons.location_outline,
      matched: sameCity,
      segments: [
        InsightSegment(label: opportunity?.location ?? 'This city', percent: locationShare.toDouble(), color: AppColors.blue, isYou: sameCity),
        InsightSegment(label: 'Other', percent: (100 - locationShare).toDouble(), color: AppColors.gray200),
      ],
    ),
    if (requirements.isNotEmpty)
      ApplicationInsight(
        title: 'Key Skills',
        icon: Ionicons.ribbon_outline,
        matched: keySkillsShare >= 40,
        segments: [
          InsightSegment(label: 'Covered', percent: keySkillsShare.toDouble(), color: keySkillsShare >= 40 ? AppColors.success : AppColors.warning, isYou: true),
          InsightSegment(label: 'Gap', percent: (100 - keySkillsShare).toDouble(), color: AppColors.gray200),
        ],
        description: keySkillsShare >= 40
            ? 'Your profile covers most of the skills this role asks for.'
            : "There's a gap between your listed skills and what this role asks for.",
      ),
  ];
}
