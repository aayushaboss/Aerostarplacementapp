import '../mockData/career_dna/career_dna_level1_data.dart';
import '../mockData/career_dna/career_dna_level2_data.dart';
import '../mockData/career_dna/career_dna_level3_data.dart';
import '../mockData/career_dna/career_dna_level4_data.dart';
import '../mockData/career_dna/career_dna_trait_pairs.dart';
import '../models/career_dna.dart';
import 'career_dna_narrative.dart';

/// One trait pair, with the student's actual raw scores for its two sides.
class SelectedTraitPair {
  final CareerDnaTraitPair pair;
  final int leftValue;
  final int rightValue;
  const SelectedTraitPair({required this.pair, required this.leftValue, required this.rightValue});
}

/// Ranks a level's candidate trait pairs by how lopsided the split actually
/// is for this student — the biggest gap is the most differentiating (and
/// most "tells you something") pair, so a near-50/50 pair naturally sorts
/// to the bottom and gets dropped once `count` is reached.
List<SelectedTraitPair> selectTopTraitPairs(Map<String, int> scores, List<CareerDnaTraitPair> candidates, {int count = 3}) {
  final scored = candidates.map((p) {
    final l = scores[p.leftKey] ?? 0;
    final r = scores[p.rightKey] ?? 0;
    return (pair: p, l: l, r: r, gap: (l - r).abs());
  }).toList()
    ..sort((a, b) => b.gap.compareTo(a.gap));
  return scored.take(count).map((s) => SelectedTraitPair(pair: s.pair, leftValue: s.l, rightValue: s.r)).toList();
}

/// Everything the compact above-the-fold summary card needs: a title, 2-3
/// selected bipolar bars, and exactly 3 lines of summary text — all sourced
/// from the same real content the downloadable PDF already draws from (via
/// career_dna_narrative.dart), nothing invented for this card specifically.
class CareerDnaTraitSummaryData {
  final String title;
  final List<SelectedTraitPair> pairs;
  final List<String> summaryLines;
  const CareerDnaTraitSummaryData({required this.title, required this.pairs, required this.summaryLines});
}

const _levelTraitPairs = {
  1: careerDnaLevel1TraitPairs,
  2: careerDnaLevel2TraitPairs,
  3: careerDnaLevel3TraitPairs,
  4: careerDnaLevel4TraitPairs,
};

/// Levels 1-4 — dispatches to the right result's dimension scores + content
/// sourcing. Returns null if that level isn't actually complete yet.
CareerDnaTraitSummaryData? buildLevelTraitSummary(CareerDnaProfile profile, int level) {
  switch (level) {
    case 1:
      final r = profile.level1;
      if (r == null) return null;
      final (strengths, growing) = narrativeSentences(r.dimensionScores, careerDnaLevel1DimensionPhrases);
      return CareerDnaTraitSummaryData(
        title: r.archetype.name,
        pairs: selectTopTraitPairs(r.dimensionScores, _levelTraitPairs[1]!),
        summaryLines: [firstSentence(r.archetype.naturalStyle), strengths, growing],
      );
    case 2:
      final r = profile.level2;
      if (r == null) return null;
      final (strengths, growing) = narrativeSentences(r.dimensionScores, careerDnaLevel2DimensionPhrases);
      return CareerDnaTraitSummaryData(
        title: r.headlineText,
        pairs: selectTopTraitPairs(r.dimensionScores, _levelTraitPairs[2]!),
        summaryLines: [careerDnaLevel2HeroSentence(r.headlineText), strengths, growing],
      );
    case 3:
      final r = profile.level3;
      if (r == null) return null;
      final (strengths, growing) = narrativeSentences(r.dimensionScores, careerDnaLevel3DimensionPhrases);
      return CareerDnaTraitSummaryData(
        title: r.profile.name,
        pairs: selectTopTraitPairs(r.dimensionScores, _levelTraitPairs[3]!),
        summaryLines: [r.profile.naturalStrength, strengths, growing],
      );
    case 4:
      final r = profile.level4;
      if (r == null) return null;
      final (strengths, growing) = narrativeSentences(r.dimensionScores, careerDnaLevel4DimensionPhrases);
      return CareerDnaTraitSummaryData(
        title: r.workStyleTitle,
        pairs: selectTopTraitPairs(r.dimensionScores, _levelTraitPairs[4]!),
        summaryLines: [r.workStyleText, strengths, growing],
      );
    default:
      return null;
  }
}

/// Level 5 — the cross-test synthesis. Uses `blendedDimensionScores` (the
/// cross-test-blended signal that actually drives `topDirections`) rather
/// than the raw own-test-only scores, since that's more representative of
/// "the result" for this level specifically.
CareerDnaTraitSummaryData buildLevel5TraitSummary(CareerDnaLevel5Result r) {
  return CareerDnaTraitSummaryData(
    title: r.topDirections.first.name,
    pairs: selectTopTraitPairs(r.blendedDimensionScores, careerDnaLevel5TraitPairs),
    summaryLines: [
      r.confidenceText,
      'Your career strengths lean into ${joinList(r.careerStrengths.take(3).toList())}.',
      "You're still building your edge in ${joinList(r.developmentAreas.take(2).toList())}.",
    ],
  );
}
