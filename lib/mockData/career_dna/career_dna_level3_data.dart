import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import '../../utils/career_dna_scoring.dart';

/// Level 3 — Social Interaction & Teamwork Orientation. 20 situational-
/// judgment questions, transcribed from the source doc, across 5 sections
/// (Working With Different People, Conflict & Collaboration, Team
/// Accountability, Influence/Leadership/Social Awareness, Real Team
/// Dynamics). Per the source doc's own explicit design principle, this is
/// deliberately NOT trying to find "the best team member" — there's no
/// universally-correct option, only a natural social operating style.
/// Options are trimmed to fit one line wherever reasonably possible.
const List<String> careerDnaLevel3Dimensions = [
  'collaboration',
  'communication',
  'socialAwareness',
  'conflictManagement',
  'influence',
  'leadershipOrientation',
  'teamAccountability',
  'empathyInclusion',
  'adaptability',
  'individualVsCollective',
];

final List<CareerDnaQuestion> careerDnaLevel3Questions = [
  const CareerDnaQuestion(
    id: 'l3q1',
    text: "A capable teammate rarely communicates; another talks constantly but contributes little. The deadline is close. What would you most likely do?",
    options: [
      CareerDnaOption(id: 'a', text: 'Focus on my own work, stay out of it.', weights: {'individualVsCollective': 3}),
      CareerDnaOption(id: 'b', text: "Speak privately to both, understand why.", weights: {'empathyInclusion': 4, 'communication': 3}),
      CareerDnaOption(id: 'c', text: 'Take control, redistribute responsibilities.', weights: {'leadershipOrientation': 4, 'influence': 2}),
      CareerDnaOption(id: 'd', text: 'Ask the team to openly discuss and agree.', weights: {'collaboration': 4, 'communication': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q2',
    text: 'Two confident members dominate discussion in your new group. You have ideas but little chance to speak.',
    options: [
      CareerDnaOption(id: 'a', text: 'Wait until I feel more comfortable.', weights: {'adaptability': 2}),
      CareerDnaOption(id: 'b', text: 'Find a moment, bring my ideas in.', weights: {'influence': 3, 'communication': 3, 'socialAwareness': 2}),
      CareerDnaOption(id: 'c', text: 'Speak more forcefully so I get heard.', weights: {'influence': 3, 'leadershipOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Build familiarity with one or two first.', weights: {'socialAwareness': 4, 'communication': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q3',
    text: 'A teammate strongly disagrees with your approach, and has valid reasons. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Defend my idea, explain why it works.', weights: {'influence': 3}),
      CareerDnaOption(id: 'b', text: 'Ask questions to understand their view.', weights: {'communication': 3, 'empathyInclusion': 3, 'conflictManagement': 2}),
      CareerDnaOption(id: 'c', text: 'Suggest testing both against the goal.', weights: {'conflictManagement': 4, 'collaboration': 2}),
      CareerDnaOption(id: 'd', text: 'Let the team decide, even if I disagree.', weights: {'collaboration': 3, 'teamAccountability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q4',
    text: 'A teammate is direct, impatient and often challenges other ideas. What would you most likely do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Keep our interaction strictly task-focused.', weights: {'individualVsCollective': 2}),
      CareerDnaOption(id: 'b', text: 'Adapt my style so discussions stay productive.', weights: {'adaptability': 4, 'communication': 3}),
      CareerDnaOption(id: 'c', text: "Tell them directly it's hurting collaboration.", weights: {'conflictManagement': 2, 'communication': 2, 'influence': 2}),
      CareerDnaOption(id: 'd', text: "Avoid it unless it affects the project.", weights: {'adaptability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q5',
    text: 'Two strong teammates stopped speaking after an argument. Their conflict is affecting the project.',
    options: [
      CareerDnaOption(id: 'a', text: 'Stay out of it; let them resolve it.', weights: {'individualVsCollective': 2}),
      CareerDnaOption(id: 'b', text: 'Speak to both separately, understand it.', weights: {'empathyInclusion': 4, 'communication': 3}),
      CareerDnaOption(id: 'c', text: 'Bring them together, refocus on the project.', weights: {'conflictManagement': 4, 'leadershipOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Inform the team leader, let them handle it.', weights: {'teamAccountability': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q6',
    text: 'Your team agreed on a decision after a long discussion. You still think it is wrong.',
    options: [
      CareerDnaOption(id: 'a', text: 'Accept it, focus on execution.', weights: {'teamAccountability': 4, 'collaboration': 2}),
      CareerDnaOption(id: 'b', text: 'Raise my concern once more, then support it.', weights: {'communication': 3, 'influence': 2, 'teamAccountability': 3}),
      CareerDnaOption(id: 'c', text: 'Keep trying to change their mind.', weights: {'influence': 3}),
      CareerDnaOption(id: 'd', text: 'Follow it, but privately do it my way.', weights: {'individualVsCollective': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q7',
    text: 'A teammate makes an obvious mistake answering a question during your group presentation. You know the right answer.',
    options: [
      CareerDnaOption(id: 'a', text: 'Correct them right away.', weights: {'influence': 2}),
      CareerDnaOption(id: 'b', text: 'Give them a moment, step in if needed.', weights: {'empathyInclusion': 3, 'socialAwareness': 3, 'collaboration': 2}),
      CareerDnaOption(id: 'c', text: "Add the info without pointing out the mistake.", weights: {'empathyInclusion': 4, 'communication': 2, 'socialAwareness': 2}),
      CareerDnaOption(id: 'd', text: "Let them finish; don't interrupt.", weights: {'adaptability': 2, 'empathyInclusion': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q8',
    text: 'A teammate is praised for an idea you originally suggested. What would bother you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'That my contribution went unacknowledged.', weights: {'individualVsCollective': 3}),
      CareerDnaOption(id: 'b', text: 'That credit within the team stayed unclear.', weights: {'individualVsCollective': 2}),
      CareerDnaOption(id: 'c', text: "I'd let it go unless it becomes a pattern.", weights: {'adaptability': 3, 'collaboration': 2}),
      CareerDnaOption(id: 'd', text: 'I would privately clarify my contribution.', weights: {'communication': 3, 'individualVsCollective': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q9',
    text: "Your team missed a deadline. Everyone contributed, but one member's delay caused most of it.",
    options: [
      CareerDnaOption(id: 'a', text: 'Discuss what went wrong as a team.', weights: {'collaboration': 4, 'empathyInclusion': 2}),
      CareerDnaOption(id: 'b', text: 'Speak privately, understand the reason.', weights: {'empathyInclusion': 4, 'communication': 3}),
      CareerDnaOption(id: 'c', text: "Make sure responsibility is clearly assigned.", weights: {'teamAccountability': 4, 'leadershipOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Focus on recovering the lost time.', weights: {'teamAccountability': 2, 'adaptability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q10',
    text: "A teammate asks you to finish part of their work — they're struggling. You already have a heavy load.",
    options: [
      CareerDnaOption(id: 'a', text: 'Help if it won\'t affect my own work.', weights: {'collaboration': 3, 'individualVsCollective': 2}),
      CareerDnaOption(id: 'b', text: 'Show them how, rather than doing it.', weights: {'empathyInclusion': 3, 'leadershipOrientation': 2}),
      CareerDnaOption(id: 'c', text: 'Ask the team to redistribute the load.', weights: {'collaboration': 3, 'leadershipOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Tell them to manage their own work.', weights: {'individualVsCollective': 4}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q11',
    text: 'Your team is underperforming and blaming outside factors. You think the team itself is partly at fault.',
    options: [
      CareerDnaOption(id: 'a', text: "Point out the team's mistakes directly.", weights: {'influence': 2}),
      CareerDnaOption(id: 'b', text: 'Ask what the team could control and change.', weights: {'leadershipOrientation': 3, 'influence': 3, 'communication': 2}),
      CareerDnaOption(id: 'c', text: 'Focus on improving my own contribution first.', weights: {'individualVsCollective': 3, 'teamAccountability': 2}),
      CareerDnaOption(id: 'd', text: 'Wait for the team leader to address it.', weights: {'adaptability': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q12',
    text: "A teammate consistently takes credit for the team's work while contributing less than others.",
    options: [
      CareerDnaOption(id: 'a', text: 'Ignore it as long as the project succeeds.', weights: {'collaboration': 3}),
      CareerDnaOption(id: 'b', text: 'Discuss it privately with the teammate.', weights: {'communication': 4, 'conflictManagement': 3}),
      CareerDnaOption(id: 'c', text: 'Make individual contributions more visible.', weights: {'socialAwareness': 2, 'individualVsCollective': 2}),
      CareerDnaOption(id: 'd', text: 'Raise the issue with the team leader.', weights: {'teamAccountability': 2, 'influence': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q13',
    text: 'Your team is split between two strategies, and the discussion has gotten repetitive.',
    options: [
      CareerDnaOption(id: 'a', text: 'Argue for the option I believe is stronger.', weights: {'influence': 3}),
      CareerDnaOption(id: 'b', text: 'Summarise both, name what should decide it.', weights: {'communication': 4, 'leadershipOrientation': 2, 'conflictManagement': 3}),
      CareerDnaOption(id: 'c', text: 'Ask the team leader to make the call.', weights: {'adaptability': 1}),
      CareerDnaOption(id: 'd', text: "Suggest testing whichever is quick to try.", weights: {'collaboration': 2, 'leadershipOrientation': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q14',
    text: "You're leading a team; a quiet member rarely speaks though their written work is strong.",
    options: [
      CareerDnaOption(id: 'a', text: 'Give them a specific chance to share.', weights: {'leadershipOrientation': 3, 'empathyInclusion': 3}),
      CareerDnaOption(id: 'b', text: 'Speak privately, understand why they\'re quiet.', weights: {'empathyInclusion': 4, 'socialAwareness': 3}),
      CareerDnaOption(id: 'c', text: 'Leave them be; not everyone needs to speak.', weights: {'adaptability': 1, 'empathyInclusion': 1}),
      CareerDnaOption(id: 'd', text: 'Ask them to present one part directly.', weights: {'leadershipOrientation': 3, 'socialAwareness': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q15',
    text: 'Made team leader as the strongest performer — another member has much better relationships in the group.',
    options: [
      CareerDnaOption(id: 'a', text: 'Ask them to help with team communication.', weights: {'leadershipOrientation': 3, 'collaboration': 2}),
      CareerDnaOption(id: 'b', text: 'Give them informal responsibility for that.', weights: {'leadershipOrientation': 2, 'empathyInclusion': 2, 'collaboration': 2}),
      CareerDnaOption(id: 'c', text: 'Keep leadership responsibilities separate.', weights: {'individualVsCollective': 2}),
      CareerDnaOption(id: 'd', text: 'Work closely, use their influence to help.', weights: {'leadershipOrientation': 4, 'influence': 3, 'collaboration': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q16',
    text: 'A skilled new member joins mid-project, knowing very little about what has already happened.',
    options: [
      CareerDnaOption(id: 'a', text: 'Give them the material, expect them to catch up.', weights: {'individualVsCollective': 2}),
      CareerDnaOption(id: 'b', text: 'Personally explain the context to them.', weights: {'empathyInclusion': 4, 'communication': 3}),
      CareerDnaOption(id: 'c', text: 'Ask another member to bring them up to speed.', weights: {'collaboration': 3, 'leadershipOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Give them a small task, build up gradually.', weights: {'adaptability': 3, 'empathyInclusion': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q17',
    text: 'Ten minutes before submission, you find a significant mistake — fully fixing it may miss the deadline.',
    options: [
      CareerDnaOption(id: 'a', text: 'Fix it even if submission gets delayed.', weights: {'teamAccountability': 4}),
      CareerDnaOption(id: 'b', text: 'Quickly discuss the risk, decide together.', weights: {'collaboration': 4, 'communication': 3}),
      CareerDnaOption(id: 'c', text: 'Submit on time, accept the mistake.', weights: {'adaptability': 2, 'teamAccountability': 1}),
      CareerDnaOption(id: 'd', text: 'Split up — some submit, some try a fix.', weights: {'leadershipOrientation': 3, 'collaboration': 2, 'adaptability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q18',
    text: 'Your team wins a competition. You contributed more than most, but everyone gets equal recognition.',
    options: [
      CareerDnaOption(id: 'a', text: "Shared recognition is fair — it was a team result.", weights: {'collaboration': 4}),
      CareerDnaOption(id: 'b', text: "I'd appreciate individual credit too.", weights: {'individualVsCollective': 3}),
      CareerDnaOption(id: 'c', text: "I'm satisfied as long as the team succeeded.", weights: {'collaboration': 3}),
      CareerDnaOption(id: 'd', text: "I'd raise it only if it affects future chances.", weights: {'individualVsCollective': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q19',
    text: "Your team is friendly, but nobody challenges weak ideas to avoid conflict.",
    options: [
      CareerDnaOption(id: 'a', text: 'Keep the peace, avoid unneeded disagreement.', weights: {'adaptability': 1}),
      CareerDnaOption(id: 'b', text: 'Start asking questions when an idea seems weak.', weights: {'conflictManagement': 4, 'communication': 3}),
      CareerDnaOption(id: 'c', text: "Tell the team avoiding conflict is hurting us.", weights: {'conflictManagement': 3, 'influence': 3}),
      CareerDnaOption(id: 'd', text: 'Challenge only the decisions that really matter.', weights: {'conflictManagement': 3, 'socialAwareness': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l3q20',
    text: 'You get to choose your preferred team for a major project. Which would you prefer?',
    options: [
      CareerDnaOption(id: 'a', text: 'Close friends, even if only average skills.', weights: {'collaboration': 3}),
      CareerDnaOption(id: 'b', text: 'Highly skilled, but very different personalities.', weights: {'adaptability': 3, 'leadershipOrientation': 2}),
      CareerDnaOption(id: 'c', text: 'Balanced, complementary, willing to challenge.', weights: {'collaboration': 4, 'conflictManagement': 3}),
      CareerDnaOption(id: 'd', text: 'One where I can take a strong lead.', weights: {'leadershipOrientation': 4, 'influence': 3}),
    ],
  ),
];

// Doc gives 3 profiles as illustrative examples only, explicitly implying
// more exist — these are extended to 6 for better coverage across the 10
// dimensions above, each following the doc's own shape (name, natural
// strength, watch-out, suitable environments). Diplomatic Mediator,
// Adaptive Team Player and Quiet Achiever are this app's own authored
// extensions, not from the source doc.
const _profiles = {
  'collaborativeInfluencer': CareerDnaSocialProfile(
    id: 'collaborativeInfluencer',
    name: 'Collaborative Influencer',
    naturalStrength: 'Builds relationships quickly and can bring different people together.',
    watchOut: 'May sometimes prioritise maintaining harmony over challenging a weak decision.',
    environments: ['Consulting', 'Sales', 'Business Development', 'HR', 'Client Management', 'Marketing', 'Project Management'],
  ),
  'independentContributor': CareerDnaSocialProfile(
    id: 'independentContributor',
    name: 'Independent Contributor',
    naturalStrength: 'Strong personal ownership and genuine reliability.',
    watchOut: 'May prefer solving problems independently rather than involving others early.',
    environments: ['Technology', 'Analytics', 'Finance', 'Research', 'Specialist Roles', 'Operations'],
  ),
  'emergingTeamLeader': CareerDnaSocialProfile(
    id: 'emergingTeamLeader',
    name: 'Emerging Team Leader',
    naturalStrength: 'Naturally takes ownership, creates direction and mobilises people.',
    watchOut: 'Worth watching that taking charge never quietly becomes taking over.',
    environments: ['Management', 'Entrepreneurship', 'Consulting', 'Business Development', 'Operations', 'Project Leadership'],
  ),
  'diplomaticMediator': CareerDnaSocialProfile(
    id: 'diplomaticMediator',
    name: 'Diplomatic Mediator',
    naturalStrength: 'De-escalates tension and finds common ground others miss entirely.',
    watchOut: 'May delay a needed hard call while still seeking full consensus.',
    environments: ['HR', 'Client Success', 'Mediation-Heavy Project Management', 'Counseling-Adjacent Business Roles'],
  ),
  'adaptiveTeamPlayer': CareerDnaSocialProfile(
    id: 'adaptiveTeamPlayer',
    name: 'Adaptive Team Player',
    naturalStrength: "Recalibrates fast to whoever they're working with, fitting into almost any team.",
    watchOut: 'Can under-assert a strong personal view while adapting to the group.',
    environments: ['Consulting', 'Agile & Cross-Functional Teams', 'Startups'],
  ),
  'quietAchiever': CareerDnaSocialProfile(
    id: 'quietAchiever',
    name: 'Quiet Achiever',
    naturalStrength: 'Dependable, high-quality individual output people learn to count on.',
    watchOut: 'Contributions can go unnoticed without some deliberate visibility.',
    environments: ['Engineering & Technical Specialist Tracks', 'Research', 'Analytics', 'QA'],
  ),
};

/// Weighted primary(x2)/secondary(x1) classifier, mirroring Level 1's own
/// mechanism — highest total wins, deterministic tie-break by this order.
const _classifierRules = [
  ('collaborativeInfluencer', 'collaboration', 'socialAwareness'),
  ('independentContributor', 'teamAccountability', 'adaptability'),
  ('emergingTeamLeader', 'leadershipOrientation', 'influence'),
  ('diplomaticMediator', 'conflictManagement', 'empathyInclusion'),
  ('adaptiveTeamPlayer', 'adaptability', 'collaboration'),
  ('quietAchiever', 'individualVsCollective', 'teamAccountability'),
];

CareerDnaSocialProfile _classifyProfile(Map<String, int> scores) {
  var bestId = _classifierRules.first.$1;
  var bestScore = -1;
  for (final (id, primary, secondary) in _classifierRules) {
    final score = 2 * (scores[primary] ?? 0) + (scores[secondary] ?? 0);
    if (score > bestScore) {
      bestScore = score;
      bestId = id;
    }
  }
  return _profiles[bestId]!;
}

CareerDnaLevel3Result computeCareerDnaLevel3Result(Map<String, String> answers) {
  final scores = normalizedDimensionScores(
    questions: careerDnaLevel3Questions,
    answers: answers,
    dimensions: careerDnaLevel3Dimensions,
  );
  return CareerDnaLevel3Result(
    dimensionScores: scores,
    profile: _classifyProfile(scores),
    completedAt: DateTime.now().toIso8601String(),
  );
}

/// Phrase per dimension for the report screen's narrative snapshot.
const careerDnaLevel3DimensionPhrases = {
  'collaboration': 'working toward shared outcomes with a team',
  'communication': 'expressing yourself clearly and listening well',
  'socialAwareness': 'reading people and group dynamics',
  'conflictManagement': 'handling disagreement constructively',
  'influence': 'gaining support without needing formal authority',
  'leadershipOrientation': 'taking responsibility and mobilising others',
  'teamAccountability': 'owning collective outcomes, not just your own',
  'empathyInclusion': 'recognising different people and perspectives',
  'adaptability': 'adjusting to different people and situations',
  'individualVsCollective': 'valuing your own individual contribution',
};
