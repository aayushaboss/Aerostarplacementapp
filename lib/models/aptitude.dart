/// Mirrors frontend/src/mockData/mockAptitude.ts.
enum AptitudeQuestionType { single, forced, slider }

AptitudeQuestionType aptitudeQuestionTypeFromString(String value) {
  switch (value) {
    case 'forced':
      return AptitudeQuestionType.forced;
    case 'slider':
      return AptitudeQuestionType.slider;
    default:
      return AptitudeQuestionType.single;
  }
}

class AptitudeQuestion {
  final String id;
  final AptitudeQuestionType type;
  final String text;
  final List<String>? options;
  final int? min;
  final int? max;
  final String? minLabel;
  final String? maxLabel;

  const AptitudeQuestion({
    required this.id,
    required this.type,
    required this.text,
    this.options,
    this.min,
    this.max,
    this.minLabel,
    this.maxLabel,
  });
}

class AptitudeMatch {
  final String cluster;
  final int matchPercent;
  final String why;
  final List<String> sampleCareers;
  final List<String> recommendedStreams;

  const AptitudeMatch({
    required this.cluster,
    required this.matchPercent,
    required this.why,
    required this.sampleCareers,
    required this.recommendedStreams,
  });

  Map<String, dynamic> toJson() => {
        'cluster': cluster,
        'matchPercent': matchPercent,
        'why': why,
        'sampleCareers': sampleCareers,
        'recommendedStreams': recommendedStreams,
      };

  factory AptitudeMatch.fromJson(Map<String, dynamic> json) => AptitudeMatch(
        cluster: json['cluster'] as String,
        matchPercent: json['matchPercent'] as int,
        why: json['why'] as String,
        sampleCareers: (json['sampleCareers'] as List).cast<String>(),
        recommendedStreams: (json['recommendedStreams'] as List).cast<String>(),
      );
}

class AptitudeResults {
  final String topMatch;
  final List<AptitudeMatch> matches;
  final String? generatedAt;

  const AptitudeResults({
    required this.topMatch,
    required this.matches,
    this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'topMatch': topMatch,
        'matches': matches.map((m) => m.toJson()).toList(),
        'generatedAt': generatedAt,
      };

  factory AptitudeResults.fromJson(Map<String, dynamic> json) => AptitudeResults(
        topMatch: json['topMatch'] as String,
        matches: (json['matches'] as List).map((m) => AptitudeMatch.fromJson(m as Map<String, dynamic>)).toList(),
        generatedAt: json['generatedAt'] as String?,
      );
}
