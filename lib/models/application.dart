/// Mirrors frontend/src/mockData/mockApplications.ts `Application`, extended
/// (prototype-only) with a status timeline + a company-bot message thread so
/// the "what happens after I apply" flow has something concrete to show.
class ApplicationOpportunitySummary {
  final String title;
  final String company;
  final String type;
  final String image;

  const ApplicationOpportunitySummary({
    required this.title,
    required this.company,
    required this.type,
    required this.image,
  });

  Map<String, dynamic> toJson() => {'title': title, 'company': company, 'type': type, 'image': image};

  factory ApplicationOpportunitySummary.fromJson(Map<String, dynamic> json) => ApplicationOpportunitySummary(
        title: json['title'] as String,
        company: json['company'] as String,
        type: json['type'] as String,
        image: json['image'] as String,
      );
}

/// One milestone in the application's journey, shown as a step in the
/// status timeline (Applied → In Review → Interview → Offer/Rejected).
class ApplicationEvent {
  final String status;
  final String title;
  final DateTime at;

  const ApplicationEvent({required this.status, required this.title, required this.at});

  Map<String, dynamic> toJson() => {'status': status, 'title': title, 'at': at.toIso8601String()};

  factory ApplicationEvent.fromJson(Map<String, dynamic> json) => ApplicationEvent(
        status: json['status'] as String,
        title: json['title'] as String,
        at: DateTime.parse(json['at'] as String),
      );
}

/// Structured interview-scheduling details attached to a bot message —
/// covers the "1:00pm offline at address" case explicitly.
class InterviewDetails {
  final String round;
  final String dateLabel;
  final String timeLabel;
  final String mode; // 'Online' | 'Offline'
  final String location; // address, or meeting-link label for online

  const InterviewDetails({
    required this.round,
    required this.dateLabel,
    required this.timeLabel,
    required this.mode,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'round': round,
        'dateLabel': dateLabel,
        'timeLabel': timeLabel,
        'mode': mode,
        'location': location,
      };

  factory InterviewDetails.fromJson(Map<String, dynamic> json) => InterviewDetails(
        round: json['round'] as String,
        dateLabel: json['dateLabel'] as String,
        timeLabel: json['timeLabel'] as String,
        mode: json['mode'] as String,
        location: json['location'] as String,
      );
}

/// A single message from the company's (simulated) bot in the per-application
/// chat thread. One-directional — this is a prototype status feed styled as
/// chat, not a live two-way conversation.
class ApplicationMessage {
  final String id;
  final String text;
  final DateTime at;
  final InterviewDetails? interview;

  const ApplicationMessage({required this.id, required this.text, required this.at, this.interview});

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'at': at.toIso8601String(),
        'interview': interview?.toJson(),
      };

  factory ApplicationMessage.fromJson(Map<String, dynamic> json) => ApplicationMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        at: DateTime.parse(json['at'] as String),
        interview: json['interview'] != null ? InterviewDetails.fromJson(json['interview'] as Map<String, dynamic>) : null,
      );
}

class Application {
  final String id;
  final String userId;
  final String opportunityId;
  final ApplicationOpportunitySummary opportunity;
  final String status;
  final String createdAt;
  final List<ApplicationEvent> timeline;
  final List<ApplicationMessage> messages;

  /// What was collected on the pre-apply screening sheet — kept on the
  /// record even though nothing surfaces it back yet, since discarding
  /// what the applicant just typed/picked would be a real data loss, not
  /// just an unused field.
  final String? note;
  final Map<String, String>? screeningAnswers;

  /// ISO-8601 timestamp set when this application is swipe-deleted; null
  /// while active. A separate field rather than a 6th `status` value —
  /// StatusBadge's color map (widgets/badges.dart) only knows the 5 real
  /// pipeline statuses and would silently fall back to "Applied" styling
  /// for anything else, so a "Deleted" status would mis-render instead of
  /// failing loudly. Keeping `status` untouched means restoring an entry
  /// shows the correct badge again immediately, with nothing to recompute.
  final String? deletedAt;

  const Application({
    required this.id,
    required this.userId,
    required this.opportunityId,
    required this.opportunity,
    required this.status,
    required this.createdAt,
    this.timeline = const [],
    this.messages = const [],
    this.note,
    this.screeningAnswers,
    this.deletedAt,
  });

  /// Unconditionally overwrites deletedAt, including clearing it back to
  /// null on restore — unlike a `??`-style copyWith, which could never
  /// un-delete an entry. Mirrors Booking.withVenue's same reasoning.
  Application withDeletedAt(String? deletedAt) {
    return Application(
      id: id,
      userId: userId,
      opportunityId: opportunityId,
      opportunity: opportunity,
      status: status,
      createdAt: createdAt,
      timeline: timeline,
      messages: messages,
      note: note,
      screeningAnswers: screeningAnswers,
      deletedAt: deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'opportunityId': opportunityId,
        'opportunity': opportunity.toJson(),
        'status': status,
        'createdAt': createdAt,
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'note': note,
        'screeningAnswers': screeningAnswers,
        'deletedAt': deletedAt,
      };

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'] as String,
        userId: json['userId'] as String,
        opportunityId: json['opportunityId'] as String,
        opportunity: ApplicationOpportunitySummary.fromJson(json['opportunity'] as Map<String, dynamic>),
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
        timeline: (json['timeline'] as List?)?.map((e) => ApplicationEvent.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        messages: (json['messages'] as List?)?.map((m) => ApplicationMessage.fromJson(m as Map<String, dynamic>)).toList() ?? const [],
        note: json['note'] as String?,
        screeningAnswers: (json['screeningAnswers'] as Map?)?.cast<String, String>(),
        deletedAt: json['deletedAt'] as String?,
      );
}
