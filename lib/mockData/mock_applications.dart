// Prototype mock data — delete when real API is wired. In-memory session store.
// Mirrors frontend/src/mockData/mockApplications.ts, extended with a status
// timeline + simulated company-bot chat (see models/application.dart).
import '../models/application.dart';
import 'mock_opportunities.dart';

DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

/// The 4 seed applications (Interview / Offer / 2× Rejected) belong to this
/// fixed showcase identity — the mock "Continue with Google" account, which
/// is given the matching stable id `demo-showcase` in AppState. A genuine
/// fresh phone/email signup gets a different id, so their Applications tab
/// starts empty and only ever shows applications they actually submitted —
/// no fabricated Offer/Interview, and no cross-account leakage of one
/// user's applications (or their notes/screening answers via a deep link)
/// into another's.
const demoShowcaseUserId = 'demo-showcase';

/// The user whose applications the list/lookup functions below return.
/// Set by AppState whenever the signed-in user changes (bootstrap, OTP
/// verify, Google sign-in, logout, cross-tab refresh). Null → no user →
/// empty everywhere.
String? _applicationsUserId;
void setApplicationsUser(String? userId) => _applicationsUserId = userId;

List<Application> _applications = _seedApplications();

List<Application> _seedApplications() {
  final apps = <Application>[];

  final interviewOpp = getOpportunityById('JOB0011');
  if (interviewOpp != null) {
    apps.add(Application(
      id: 'app-seed-interview',
      userId: demoShowcaseUserId,
      opportunityId:interviewOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: interviewOpp.title,
        company: interviewOpp.company,
        type: interviewOpp.type,
        image: interviewOpp.image,
      ),
      status: 'Interview',
      createdAt: _daysAgo(6).toIso8601String(),
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(6)),
        ApplicationEvent(status: 'In Review', title: 'Resume under review', at: _daysAgo(4)),
        ApplicationEvent(status: 'Interview', title: 'Interview scheduled', at: _daysAgo(1)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: "Good news — you've cleared the first screen. We're comparing your profile with the shortlist now.",
          at: _daysAgo(4),
        ),
        ApplicationMessage(
          id: 'm3',
          text: "You're shortlisted! 🎉 Here are your interview details for ${interviewOpp.company}:",
          at: _daysAgo(1),
          interview: InterviewDetails(
            round: 'Interview Round 1',
            dateLabel: 'Mon, 18 Aug',
            timeLabel: '1:00 PM',
            mode: 'Offline',
            location: '${interviewOpp.company} office, ${interviewOpp.location}',
          ),
        ),
        ApplicationMessage(
          id: 'm4',
          text: 'Bring a printed resume and photo ID. Arrive 10 min early and ask for the campus-hiring desk.',
          at: _daysAgo(1),
        ),
      ],
    ));
  }

  final offerOpp = getOpportunityById('JOB0002');
  if (offerOpp != null) {
    apps.add(Application(
      id: 'app-seed-offer',
      userId: demoShowcaseUserId,
      opportunityId:offerOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: offerOpp.title,
        company: offerOpp.company,
        type: offerOpp.type,
        image: offerOpp.image,
      ),
      status: 'Offer',
      createdAt: _daysAgo(12).toIso8601String(),
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(12)),
        ApplicationEvent(status: 'In Review', title: 'Resume under review', at: _daysAgo(9)),
        ApplicationEvent(status: 'Interview', title: 'Interview completed', at: _daysAgo(5)),
        ApplicationEvent(status: 'Offer', title: 'Offer extended', at: _daysAgo(2)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: 'Your portfolio stood out — moving you to the interview round.',
          at: _daysAgo(9),
        ),
        ApplicationMessage(
          id: 'm3',
          text: 'Thanks for chatting with our design lead this week — the team is finalizing decisions now.',
          at: _daysAgo(5),
        ),
        ApplicationMessage(
          id: 'm4',
          text: "🎉 Congratulations! ${offerOpp.company} would like to offer you the ${offerOpp.title} role. Check your registered email for the formal offer letter and next steps.",
          at: _daysAgo(2),
        ),
      ],
    ));
  }

  final rejectedOpp = getOpportunityById('JOB0021');
  if (rejectedOpp != null) {
    apps.add(Application(
      id: 'app-seed-rejected',
      userId: demoShowcaseUserId,
      opportunityId:rejectedOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: rejectedOpp.title,
        company: rejectedOpp.company,
        type: rejectedOpp.type,
        image: rejectedOpp.image,
      ),
      status: 'Rejected',
      createdAt: _daysAgo(9).toIso8601String(),
      // Only two milestones — some companies skip straight from application
      // to a walk-in round and a same-day decision, no separate review step.
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(9)),
        ApplicationEvent(status: 'Rejected', title: 'Decision received', at: _daysAgo(2)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: "${rejectedOpp.company} moved forward with a candidate whose campaign work leaned more into paid-social — this one's closed.",
          at: _daysAgo(2),
        ),
      ],
    ));
  }

  final secondRejectedOpp = getOpportunityById('JOB0031');
  if (secondRejectedOpp != null) {
    apps.add(Application(
      id: 'app-seed-rejected-2',
      userId: demoShowcaseUserId,
      opportunityId:secondRejectedOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: secondRejectedOpp.title,
        company: secondRejectedOpp.company,
        type: secondRejectedOpp.type,
        image: secondRejectedOpp.image,
      ),
      status: 'Rejected',
      createdAt: _daysAgo(15).toIso8601String(),
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(15)),
        ApplicationEvent(status: 'In Review', title: 'Resume under review', at: _daysAgo(12)),
        ApplicationEvent(status: 'Rejected', title: 'Decision received', at: _daysAgo(7)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: 'Your resume is with the editorial team now.',
          at: _daysAgo(12),
        ),
        ApplicationMessage(
          id: 'm3',
          text: "${secondRejectedOpp.company} decided to go with someone who'd already run campaigns in their niche — this one's closed.",
          at: _daysAgo(7),
        ),
      ],
    ));
  }

  return apps;
}

/// Every list/lookup below is scoped to the current signed-in user (set by
/// AppState via [setApplicationsUser]) — so one account never sees
/// another's applications, and a fresh signup starts with an empty tab.
bool _mine(Application a) => a.userId == _applicationsUserId;

/// Excludes soft-deleted entries — see [removeApplication]/[deletedAt].
/// Sorted once, centrally, so every caller sees the same order: an Offer
/// is the one status worth surfacing above everything else regardless of
/// when it came in, so those go first; everything else (including other
/// Offers relative to each other) falls back to most-recently-applied
/// first.
List<Application> listApplications() {
  final apps = _applications.where((a) => _mine(a) && a.deletedAt == null).toList();
  apps.sort((a, b) {
    final aOffer = a.status == 'Offer' ? 0 : 1;
    final bOffer = b.status == 'Offer' ? 0 : 1;
    if (aOffer != bOffer) return aOffer.compareTo(bOffer);
    return b.createdAt.compareTo(a.createdAt);
  });
  return apps;
}

/// Single source of truth for "has the signed-in user already applied to
/// this opportunity" — every job/opportunity card that shows an
/// Apply/Applied state should use this instead of hand-rolling the same
/// listApplications() lookup (several call sites used to, and drifted:
/// some hardcoded `false` regardless of the real answer).
bool isOpportunityApplied(String opportunityId) =>
    _applications.any((a) => _mine(a) && a.opportunityId == opportunityId && a.deletedAt == null);

/// Soft delete — swiping an application away no longer removes it outright,
/// it just marks when it was deleted. The entry never actually leaves
/// _applications, which is what makes [restoreApplication] trivial (no
/// index bookkeeping needed) and lets both the swipe's own SnackBar-undo
/// and the Recently Deleted screen share one restore path.
void removeApplication(String id) =>
    _applications = _applications.map((a) => a.id == id ? a.withDeletedAt(DateTime.now().toIso8601String()) : a).toList();

/// Entries currently in the trash, most-recently-deleted first.
/// TODO: auto-purge entries older than ~30 days (Gmail/Drive-style trash
/// retention) once there's a real backend to run that on a schedule — no
/// timer in this prototype, so deleted entries just persist for the session.
List<Application> listRecentlyDeleted() {
  final deleted = _applications.where((a) => _mine(a) && a.deletedAt != null).toList();
  deleted.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  return deleted;
}

/// Un-deletes — used both by the swipe's fast SnackBar-undo and by the
/// Recently Deleted screen's Restore action.
void restoreApplication(String id) =>
    _applications = _applications.map((a) => a.id == id ? a.withDeletedAt(null) : a).toList();

/// True hard removal — for a "Delete forever" action on an already-trashed
/// entry.
void permanentlyDelete(String id) => _applications = _applications.where((a) => a.id != id).toList();

/// Deep-link safe: a link to another user's application id (or a
/// soft-deleted one) returns null rather than rendering someone else's
/// application detail — note, screening answers and all.
Application? getApplicationById(String id) {
  final matches = _applications.where((a) => _mine(a) && a.id == id && a.deletedAt == null);
  return matches.isEmpty ? null : matches.first;
}

/// Returns `null` if the opportunity can't be resolved (nothing created);
/// `(isNew: false)` if the current user already has a live application for
/// it (a no-op — no duplicate ever created); `(isNew: true)` on a genuine
/// new application. Callers use `isNew` to decide whether to show the full
/// "submitted!" confirmation or just an "already applied" note.
({Application application, bool isNew})? createApplication(
  String opportunityId, {
  String? note,
  Map<String, String>? screeningAnswers,
}) {
  // Excludes soft-deleted matches — otherwise re-applying after deleting an
  // application for this opportunity would just hand back the still-hidden
  // deleted entry instead of creating a fresh, visible one.
  final existing = _applications.where((a) => _mine(a) && a.opportunityId == opportunityId && a.deletedAt == null);
  if (existing.isNotEmpty) return (application: existing.first, isNew: false);
  final opp = getOpportunityById(opportunityId);
  if (opp == null) return null;
  final now = DateTime.now();
  final application = Application(
    id: 'app-${now.microsecondsSinceEpoch}',
    userId: _applicationsUserId ?? demoShowcaseUserId,
    opportunityId: opportunityId,
    opportunity: ApplicationOpportunitySummary(
      title: opp.title,
      company: opp.company,
      type: opp.type,
      image: opp.image,
    ),
    status: 'Applied',
    createdAt: now.toIso8601String(),
    note: note,
    screeningAnswers: screeningAnswers,
    timeline: [
      ApplicationEvent(status: 'Applied', title: 'Application submitted', at: now),
    ],
    // No opening "thanks for applying" message — the Applied timeline step
    // above already says that; `messages` defaults to empty until there's
    // an actual update to show.
  );
  _applications = [application, ..._applications];
  return (application: application, isNew: true);
}
