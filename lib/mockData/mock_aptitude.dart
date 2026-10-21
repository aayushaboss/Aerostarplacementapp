// Prototype mock data — delete when real API is wired.
// Mirrors frontend/src/mockData/mockAptitude.ts.
import '../models/aptitude.dart';

const List<AptitudeQuestion> mockAptitudeQuestions = [
  AptitudeQuestion(
    id: 'q1',
    type: AptitudeQuestionType.single,
    text: 'Which activity sounds the most fun to you?',
    options: [
      'Solving a tricky puzzle',
      'Helping a friend feel better',
      'Designing a poster',
      'Running a small stall',
    ],
  ),
  AptitudeQuestion(
    id: 'q2',
    type: AptitudeQuestionType.single,
    text: 'In a group project, you naturally become the…',
    options: ['Idea generator', 'Organizer / planner', 'Presenter', 'Builder / maker'],
  ),
  AptitudeQuestion(
    id: 'q3',
    type: AptitudeQuestionType.slider,
    text: 'I enjoy working with numbers and data.',
    min: 1,
    max: 5,
    minLabel: 'Not at all',
    maxLabel: 'Love it',
  ),
  AptitudeQuestion(
    id: 'q4',
    type: AptitudeQuestionType.forced,
    text: 'Would you rather…',
    options: ['Fix a broken machine', 'Write a short story'],
  ),
  AptitudeQuestion(
    id: 'q5',
    type: AptitudeQuestionType.single,
    text: 'A perfect weekend project would be…',
    options: [
      'Coding a small app',
      'Volunteering at a camp',
      'Painting or editing videos',
      'Selling handmade items',
    ],
  ),
  AptitudeQuestion(
    id: 'q6',
    type: AptitudeQuestionType.slider,
    text: 'I like understanding how the human body works.',
    min: 1,
    max: 5,
    minLabel: 'Not really',
    maxLabel: 'Very much',
  ),
  AptitudeQuestion(
    id: 'q7',
    type: AptitudeQuestionType.forced,
    text: 'Would you rather…',
    options: ['Lead a team', 'Work quietly on your own'],
  ),
  AptitudeQuestion(
    id: 'q8',
    type: AptitudeQuestionType.single,
    text: 'Which school subject do you look forward to?',
    options: ['Mathematics / Physics', 'Biology / Chemistry', 'Economics / Business', 'Art / Literature'],
  ),
  AptitudeQuestion(
    id: 'q9',
    type: AptitudeQuestionType.slider,
    text: 'I enjoy convincing and negotiating with people.',
    min: 1,
    max: 5,
    minLabel: 'Avoid it',
    maxLabel: 'Thrive on it',
  ),
  AptitudeQuestion(
    id: 'q10',
    type: AptitudeQuestionType.single,
    text: 'A problem feels exciting when it is…',
    options: [
      'Logical and technical',
      'About people and care',
      'Open-ended and creative',
      'About money and strategy',
    ],
  ),
  AptitudeQuestion(
    id: 'q11',
    type: AptitudeQuestionType.forced,
    text: 'Would you rather…',
    options: ['Build a robot', 'Plan a fund-raising event'],
  ),
  AptitudeQuestion(
    id: 'q12',
    type: AptitudeQuestionType.single,
    text: 'People often praise you for being…',
    options: ['Analytical', 'Caring', 'Imaginative', 'Persuasive'],
  ),
];

// Flavor text per cluster, keyed against the same 5-cluster taxonomy
// Course.cluster already uses (mock_courses.dart) — computeAptitudeResults
// below picks the top 3 by computed score and attaches this copy, so
// results plug straight into the existing recommendedCourses(clusters)
// pipeline with no downstream changes needed.
const _clusterCopy = <String, ({String why, List<String> sampleCareers, List<String> recommendedStreams})>{
  'Technology & Computer Science': (
    why: 'You enjoy logical problem-solving and building things.',
    sampleCareers: ['Software Engineer', 'Data Analyst', 'Product Manager'],
    recommendedStreams: ['Science (PCM)', 'Computer Science'],
  ),
  'Commerce & Finance': (
    why: 'You like strategy, numbers and real-world impact.',
    sampleCareers: ['Financial Analyst', 'Entrepreneur', 'Accountant'],
    recommendedStreams: ['Commerce', 'Economics'],
  ),
  'Design & Creative': (
    why: 'You have a creative, imaginative streak.',
    sampleCareers: ['UX Designer', 'Content Creator', 'Architect'],
    recommendedStreams: ['Arts', 'Design'],
  ),
  'Medical & Healthcare': (
    why: "You're drawn to caring for people and how the body works.",
    sampleCareers: ['Doctor', 'Nurse', 'Biotechnologist'],
    recommendedStreams: ['Science (PCB)', 'Biology'],
  ),
  'Humanities & Law': (
    why: 'You connect naturally with people, ideas, and expression.',
    sampleCareers: ['Lawyer', 'Journalist', 'Civil Services Officer'],
    recommendedStreams: ['Humanities', 'Political Science'],
  ),
};

// Per-option cluster weights for single/forced questions — the "primary"
// cluster an option signals gets weight 2, an option can also carry a
// weaker weight-1 secondary cluster when its real-world content genuinely
// overlaps two fields (e.g. "Presenter" signals both Humanities/comms and
// Commerce/business). Authored directly against each question's actual
// text/options above, not arbitrary.
const _singleForcedWeights = <String, Map<String, Map<String, int>>>{
  'q1': {
    'Solving a tricky puzzle': {'Technology & Computer Science': 2},
    'Helping a friend feel better': {'Medical & Healthcare': 2},
    'Designing a poster': {'Design & Creative': 2},
    'Running a small stall': {'Commerce & Finance': 2},
  },
  'q2': {
    'Idea generator': {'Design & Creative': 2, 'Humanities & Law': 1},
    'Organizer / planner': {'Commerce & Finance': 2},
    'Presenter': {'Humanities & Law': 2, 'Commerce & Finance': 1},
    'Builder / maker': {'Technology & Computer Science': 2},
  },
  'q4': {
    'Fix a broken machine': {'Technology & Computer Science': 2},
    'Write a short story': {'Humanities & Law': 2},
  },
  'q5': {
    'Coding a small app': {'Technology & Computer Science': 2},
    'Volunteering at a camp': {'Medical & Healthcare': 2, 'Humanities & Law': 1},
    'Painting or editing videos': {'Design & Creative': 2},
    'Selling handmade items': {'Commerce & Finance': 2},
  },
  'q7': {
    'Lead a team': {'Commerce & Finance': 2, 'Humanities & Law': 1},
    'Work quietly on your own': {'Technology & Computer Science': 2, 'Design & Creative': 1},
  },
  'q8': {
    'Mathematics / Physics': {'Technology & Computer Science': 2},
    'Biology / Chemistry': {'Medical & Healthcare': 2},
    'Economics / Business': {'Commerce & Finance': 2},
    'Art / Literature': {'Design & Creative': 1, 'Humanities & Law': 2},
  },
  'q10': {
    'Logical and technical': {'Technology & Computer Science': 2},
    'About people and care': {'Medical & Healthcare': 2},
    'Open-ended and creative': {'Design & Creative': 2},
    'About money and strategy': {'Commerce & Finance': 2},
  },
  'q11': {
    'Build a robot': {'Technology & Computer Science': 2},
    'Plan a fund-raising event': {'Commerce & Finance': 2, 'Humanities & Law': 1},
  },
  'q12': {
    'Analytical': {'Technology & Computer Science': 2},
    'Caring': {'Medical & Healthcare': 2},
    'Imaginative': {'Design & Creative': 2},
    'Persuasive': {'Commerce & Finance': 2, 'Humanities & Law': 1},
  },
};

// Slider questions (1-5) contribute proportionally to their value, split
// across whichever clusters that question's text actually probes.
const _sliderWeights = <String, Map<String, int>>{
  'q3': {'Technology & Computer Science': 1, 'Commerce & Finance': 1},
  'q6': {'Medical & Healthcare': 1},
  'q9': {'Commerce & Finance': 1, 'Humanities & Law': 1},
};

/// Replaces the old hardcoded [mockAptitudeResults] — real (if simple)
/// weighted scoring against what the user actually answered, instead of
/// returning the same static result to every user regardless of input.
/// [answers] is keyed by question id, values are the selected option
/// String (single/forced) or the 1-5 int (slider) — the exact shape
/// aptitude_screen.dart's `_answers` map already stores.
AptitudeResults computeAptitudeResults(Map<String, dynamic> answers) {
  final totals = <String, double>{};
  final maxPossible = <String, double>{};

  for (final q in mockAptitudeQuestions) {
    if (q.type == AptitudeQuestionType.slider) {
      final weights = _sliderWeights[q.id];
      if (weights == null) continue;
      final maxVal = (q.max ?? 5).toDouble();
      final answer = answers[q.id];
      final value = answer is num ? answer.toDouble() : null;
      for (final entry in weights.entries) {
        maxPossible[entry.key] = (maxPossible[entry.key] ?? 0) + entry.value * maxVal;
        if (value != null) {
          totals[entry.key] = (totals[entry.key] ?? 0) + entry.value * value;
        }
      }
    } else {
      final optionWeights = _singleForcedWeights[q.id];
      if (optionWeights == null) continue;
      // Only one option can ever be picked — a cluster's max contribution
      // from this question is the highest weight any single option offers
      // it, not the sum across every option.
      final perClusterMax = <String, int>{};
      for (final optWeights in optionWeights.values) {
        for (final entry in optWeights.entries) {
          perClusterMax.update(entry.key, (v) => v > entry.value ? v : entry.value, ifAbsent: () => entry.value);
        }
      }
      for (final entry in perClusterMax.entries) {
        maxPossible[entry.key] = (maxPossible[entry.key] ?? 0) + entry.value;
      }
      final chosen = answers[q.id];
      final chosenWeights = chosen is String ? optionWeights[chosen] : null;
      if (chosenWeights != null) {
        for (final entry in chosenWeights.entries) {
          totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
        }
      }
    }
  }

  final matches = _clusterCopy.entries.map((e) {
    final max = maxPossible[e.key] ?? 0;
    final total = totals[e.key] ?? 0;
    final percent = max > 0 ? ((total / max) * 100).round().clamp(0, 100) : 0;
    return AptitudeMatch(
      cluster: e.key,
      matchPercent: percent,
      why: e.value.why,
      sampleCareers: e.value.sampleCareers,
      recommendedStreams: e.value.recommendedStreams,
    );
  }).toList()
    ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));

  final top = matches.take(3).toList();
  return AptitudeResults(
    topMatch: top.first.cluster,
    matches: top,
    // Set at the moment results are actually computed, not once at
    // first-touch of this library (see the old `final` constant this
    // replaced — Dart only evaluates a top-level final once, ever).
    generatedAt: DateTime.now().toIso8601String(),
  );
}
