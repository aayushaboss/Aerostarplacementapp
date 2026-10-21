import '../mockData/mock_profile_options.dart' show validRoles;
import 'opportunity.dart';
import 'user.dart';

/// Shown as a Tooltip on every match badge (see matchLabelFor below) — the
/// score itself was rendered everywhere with zero explanation of what it
/// meant or how to raise it. One shared string so the wording can't drift
/// between the 3 different card widgets that render this badge.
const matchExplanation =
    'Based on how closely this role lines up with your interested roles, resume skills, and profile — add more skills to your resume to raise it.';

/// Personalized relevance + deadline-urgency helpers for opportunity cards.
/// Prototype heuristic (not a real ranking model): weights the user's
/// selected "Interested roles" from onboarding heavily, with a smaller
/// boost for resume-skill keyword overlap against the role's requirements.
extension OpportunityMatch on Opportunity {
  /// 0–100. Null-safe against a user with no roles/resume yet.
  int matchScoreFor(User? user) {
    if (user == null) return 0;
    var score = 0;

    // Old role names map onto the current departments (see validRoles).
    final roles = validRoles(user.roles);
    if (roles.any((r) => r.toLowerCase() == category.toLowerCase())) {
      score += 60;
    }

    final skills = user.resume?.skills ?? const [];
    if (skills.isNotEmpty) {
      final reqText = requirements.join(' ').toLowerCase();
      final hits = skills.where((s) => reqText.contains(s.toLowerCase())).length;
      score += hits.clamp(0, 5) * 8;
    }

    // Postgrads skew toward full-time roles, undergrads toward internships
    // — a modest tie-breaker on top of the role/skill signals above, not a
    // replacement for them.
    if (user.segment == Segment.pg && type == 'Full-time') score += 15;
    if (user.segment == Segment.ug && type == 'Internship') score += 15;

    return score.clamp(0, 100);
  }

  /// Short badge label, or null when the match isn't strong enough to
  /// call out (avoids diluting the signal by labelling every card).
  String? matchLabelFor(User? user) {
    final score = matchScoreFor(user);
    if (score >= 80) return 'Great fit';
    if (score >= 50) return '$score% match';
    return null;
  }

  int? get daysUntilDeadline {
    try {
      final d = DateTime.parse(deadline);
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      return d.difference(todayMidnight).inDays;
    } catch (_) {
      return null;
    }
  }

  /// Short urgency label for the card, or null once it's far enough out
  /// that surfacing it would just be noise.
  String? get deadlineLabel {
    final days = daysUntilDeadline;
    if (days == null || days > 7) return null;
    if (days <= 0) return 'Closing today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }

  bool get deadlineIsUrgent => (daysUntilDeadline ?? 99) <= 3;
}
