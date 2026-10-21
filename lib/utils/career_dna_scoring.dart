import '../models/career_dna_question.dart';

/// Shared scoring function reused by all 5 Career DNA levels — avoids
/// duplicating this arithmetic across ~4000 lines of per-level question
/// data. Deliberately NOT a simple A=1/B=2/C=3/D=4 tally (every source doc
/// explicitly warns against that): each option carries its own weighted
/// contribution across several dimensions at once (see CareerDnaOption),
/// and this sums + normalizes those, per dimension, to a 0-100 scale.
Map<String, int> normalizedDimensionScores({
  required List<CareerDnaQuestion> questions,
  required Map<String, String> answers, // questionId -> chosen optionId
  required List<String> dimensions,
}) {
  final raw = {for (final d in dimensions) d: 0};
  final maxPossible = {for (final d in dimensions) d: 0};

  for (final q in questions) {
    for (final d in dimensions) {
      final maxForQuestion = q.options.map((o) => o.weights[d] ?? 0).fold(0, (a, b) => a > b ? a : b);
      maxPossible[d] = maxPossible[d]! + maxForQuestion;
    }
    final chosenId = answers[q.id];
    if (chosenId == null) continue;
    final chosen = q.options.where((o) => o.id == chosenId).firstOrNull;
    if (chosen == null) continue;
    for (final d in dimensions) {
      raw[d] = raw[d]! + (chosen.weights[d] ?? 0);
    }
  }

  return {
    for (final d in dimensions) d: maxPossible[d] == 0 ? 0 : ((raw[d]! / maxPossible[d]!) * 100).round().clamp(0, 100),
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
