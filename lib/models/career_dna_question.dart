/// Shared question shape for every Career DNA level. One MCQ, one weighted
/// option per answer — the weight matrix is never shown to the student (see
/// each level's own data file for the authoring rule that produced it).
class CareerDnaOption {
  final String id; // 'a'..'d'
  final String text;

  /// dimension slug -> 0..4 ( — =0, Low=1, Medium=2, High=3, VeryHigh=4 ),
  /// transcribed from each level's own source-doc trait table.
  final Map<String, int> weights;

  const CareerDnaOption({required this.id, required this.text, required this.weights});
}

class CareerDnaQuestion {
  final String id;
  final String text;
  final List<CareerDnaOption> options;

  /// Level 5's Career Trade-offs section only — a forced A/B choice plus two
  /// softer "it depends" hedge options, per that level's own anti-gaming
  /// design (see its data file). Every other level's questions leave this
  /// false; nothing in the shared quiz screen actually branches on it today,
  /// it's purely descriptive metadata for a future refinement.
  final bool forcedChoice;

  const CareerDnaQuestion({required this.id, required this.text, required this.options, this.forcedChoice = false});
}
