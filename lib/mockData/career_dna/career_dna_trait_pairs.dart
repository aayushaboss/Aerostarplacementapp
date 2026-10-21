/// Candidate bipolar trait pairs per Career DNA level, used to build the
/// compact "relative-dominance" result bars (see career_dna_trait_summary.dart).
/// None of these are true independent bipolar psychometric pairs — every
/// dimension in every level is scored as its own independent 0-100 "more is
/// generally more" score. These pairs are a deliberate reframing: two
/// already-scored, sensible dimensions shown as a relative split ("which
/// pulls stronger for you"), not a claim that scoring high on one
/// necessarily means scoring low on the other. Both labels in every pair
/// are positively framed — never a good-vs-bad axis.
class CareerDnaTraitPair {
  final String leftKey;
  final String leftLabel;
  final String rightKey;
  final String rightLabel;

  const CareerDnaTraitPair({
    required this.leftKey,
    required this.leftLabel,
    required this.rightKey,
    required this.rightLabel,
  });
}

const careerDnaLevel1TraitPairs = [
  CareerDnaTraitPair(leftKey: 'leadershipInitiative', leftLabel: 'Leading', rightKey: 'teamOrientation', rightLabel: 'Collaborating'),
  CareerDnaTraitPair(leftKey: 'decisionMaking', leftLabel: 'Deciding', rightKey: 'adaptability', rightLabel: 'Adapting'),
  CareerDnaTraitPair(leftKey: 'socialOrientation', leftLabel: 'Connecting', rightKey: 'problemSolving', rightLabel: 'Analyzing'),
  CareerDnaTraitPair(leftKey: 'ambitionGrowth', leftLabel: 'Driving', rightKey: 'resilience', rightLabel: 'Steadying'),
  CareerDnaTraitPair(leftKey: 'communicationConfidence', leftLabel: 'Expressing', rightKey: 'learningAgility', rightLabel: 'Absorbing'),
];

const careerDnaLevel2TraitPairs = [
  CareerDnaTraitPair(leftKey: 'analytical', leftLabel: 'Analytical', rightKey: 'creative', rightLabel: 'Creative'),
  CareerDnaTraitPair(leftKey: 'peopleSocial', leftLabel: 'People', rightKey: 'technology', rightLabel: 'Technical'),
  CareerDnaTraitPair(leftKey: 'businessLeadership', leftLabel: 'Leading', rightKey: 'executionOperations', rightLabel: 'Executing'),
  CareerDnaTraitPair(leftKey: 'entrepreneurialDrive', leftLabel: 'Building', rightKey: 'learningExpertise', rightLabel: 'Mastering'),
  CareerDnaTraitPair(leftKey: 'analytical', leftLabel: 'Data-driven', rightKey: 'peopleSocial', rightLabel: 'People-driven'),
];

const careerDnaLevel3TraitPairs = [
  CareerDnaTraitPair(leftKey: 'leadershipOrientation', leftLabel: 'Leading', rightKey: 'teamAccountability', rightLabel: 'Team-first'),
  CareerDnaTraitPair(leftKey: 'influence', leftLabel: 'Influencing', rightKey: 'empathyInclusion', rightLabel: 'Including'),
  CareerDnaTraitPair(leftKey: 'individualVsCollective', leftLabel: 'Team-oriented', rightKey: 'leadershipOrientation', rightLabel: 'Self-directed'),
  CareerDnaTraitPair(leftKey: 'conflictManagement', leftLabel: 'Resolving', rightKey: 'adaptability', rightLabel: 'Adapting'),
  CareerDnaTraitPair(leftKey: 'communication', leftLabel: 'Expressing', rightKey: 'socialAwareness', rightLabel: 'Perceiving'),
];

const careerDnaLevel4TraitPairs = [
  CareerDnaTraitPair(leftKey: 'ownership', leftLabel: 'Self-driven', rightKey: 'instructionManagement', rightLabel: 'Guided'),
  CareerDnaTraitPair(leftKey: 'attentionToDetail', leftLabel: 'Precise', rightKey: 'adaptabilityAtWork', rightLabel: 'Flexible'),
  CareerDnaTraitPair(leftKey: 'executionDiscipline', leftLabel: 'Consistent', rightKey: 'continuousImprovement', rightLabel: 'Improving'),
  CareerDnaTraitPair(leftKey: 'professionalJudgement', leftLabel: 'Independent', rightKey: 'feedbackOrientation', rightLabel: 'Coachable'),
  CareerDnaTraitPair(leftKey: 'reliability', leftLabel: 'Steady', rightKey: 'prioritisation', rightLabel: 'Strategic'),
];

const careerDnaLevel5TraitPairs = [
  CareerDnaTraitPair(leftKey: 'analyticalData', leftLabel: 'Analytical', rightKey: 'creativeMedia', rightLabel: 'Creative'),
  CareerDnaTraitPair(leftKey: 'peopleClient', leftLabel: 'People-facing', rightKey: 'technologyProduct', rightLabel: 'Tech-focused'),
  CareerDnaTraitPair(leftKey: 'managementLeadership', leftLabel: 'Leading', rightKey: 'operations', rightLabel: 'Operating'),
  CareerDnaTraitPair(leftKey: 'salesBusinessDevelopment', leftLabel: 'Selling', rightKey: 'entrepreneurial', rightLabel: 'Founding'),
  CareerDnaTraitPair(leftKey: 'entrepreneurial', leftLabel: 'Building', rightKey: 'operations', rightLabel: 'Running'),
];
