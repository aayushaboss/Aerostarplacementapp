import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import '../../utils/career_dna_scoring.dart';

/// Level 1 — Personality & Behaviour. 20 questions, transcribed verbatim
/// from the source assessment doc. Weight matrices are authored using that
/// doc's own scale (— = 0, Low = 1, Medium = 2, High = 3, VeryHigh = 4),
/// applied against this level's 10 Core Personality Dimensions — Q6's
/// weights below are the doc's own literal worked example; every other
/// question's weights follow the same rule mechanically from its stated
/// Primary Traits. Never shown to the student — see career_dna_scoring.dart.
///
/// Option `text` strings are trimmed to fit one line on a typical phone
/// width wherever reasonably possible (a handful still wrap to 2 lines) —
/// per direct feedback that most options reading as 2 lines was too much to
/// read. `id`/`weights` are untouched by that trim; only display text moved.
const List<String> careerDnaLevel1Dimensions = [
  'leadershipInitiative',
  'communicationConfidence',
  'teamOrientation',
  'adaptability',
  'decisionMaking',
  'problemSolving',
  'learningAgility',
  'resilience',
  'socialOrientation',
  'ambitionGrowth',
];

/// Phrase per dimension, for the report screen's narrative snapshot — never
/// the raw dimension key/label, and never a number (see the report screen's
/// own doc comment on why percentages were dropped entirely).
const careerDnaLevel1DimensionPhrases = {
  'leadershipInitiative': 'stepping up and taking initiative',
  'communicationConfidence': 'speaking up with confidence',
  'teamOrientation': 'working well with a team',
  'adaptability': 'adapting quickly to change',
  'decisionMaking': 'making clear decisions',
  'problemSolving': 'solving problems',
  'learningAgility': 'picking up new things fast',
  'resilience': 'bouncing back from setbacks',
  'socialOrientation': 'connecting with people',
  'ambitionGrowth': 'pushing yourself toward bigger goals',
};

final List<CareerDnaQuestion> careerDnaLevel1Questions = [
  const CareerDnaQuestion(
    id: 'l1q1',
    text: "You join a new group activity where you don't know anyone. What would you naturally do?",
    options: [
      CareerDnaOption(id: 'a', text: 'Talk to someone friendly.', weights: {'socialOrientation': 4, 'communicationConfidence': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'b', text: 'Observe before joining in.', weights: {'socialOrientation': 1, 'communicationConfidence': 1, 'adaptability': 3}),
      CareerDnaOption(id: 'c', text: 'Find someone familiar to me.', weights: {'socialOrientation': 2, 'communicationConfidence': 1, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'Focus on the activity itself.', weights: {'socialOrientation': 2, 'communicationConfidence': 2, 'adaptability': 4}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q2',
    text: 'Your group has several different ideas for a shared project. What role would you naturally take?',
    options: [
      CareerDnaOption(id: 'a', text: 'Combine the strongest ideas.', weights: {'teamOrientation': 4, 'leadershipInitiative': 2, 'communicationConfidence': 2}),
      CareerDnaOption(id: 'b', text: 'Share the idea I think is best.', weights: {'teamOrientation': 1, 'leadershipInitiative': 3, 'communicationConfidence': 4}),
      CareerDnaOption(id: 'c', text: 'Listen to everyone first.', weights: {'teamOrientation': 3, 'leadershipInitiative': 1, 'communicationConfidence': 3}),
      CareerDnaOption(id: 'd', text: "Execute the group's choice.", weights: {'teamOrientation': 3, 'leadershipInitiative': 1, 'communicationConfidence': 1, 'problemSolving': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q3',
    text: 'You are asked to do something you have never done before. What sounds most like you?',
    options: [
      CareerDnaOption(id: 'a', text: 'Try it and learn as I go.', weights: {'learningAgility': 4, 'adaptability': 3, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Understand it, then begin.', weights: {'learningAgility': 2, 'adaptability': 1, 'problemSolving': 3}),
      CareerDnaOption(id: 'c', text: "Learn from someone who's done it.", weights: {'learningAgility': 2, 'socialOrientation': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'Explore different ways first.', weights: {'learningAgility': 3, 'adaptability': 4, 'problemSolving': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q4',
    text: 'A close friend achieves something that you also wanted. What would most naturally happen?',
    options: [
      CareerDnaOption(id: 'a', text: 'Celebrate their achievement.', weights: {'teamOrientation': 4, 'socialOrientation': 3, 'ambitionGrowth': 1}),
      CareerDnaOption(id: 'b', text: 'Get curious how they did it.', weights: {'learningAgility': 3, 'ambitionGrowth': 2, 'teamOrientation': 2}),
      CareerDnaOption(id: 'c', text: 'Compare my progress to theirs.', weights: {'ambitionGrowth': 3, 'teamOrientation': 1, 'socialOrientation': 1}),
      CareerDnaOption(id: 'd', text: 'Use it to motivate my own goals.', weights: {'ambitionGrowth': 4, 'teamOrientation': 2, 'learningAgility': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q5',
    text: 'You have planned your day, but an unexpected situation changes your plans. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Quickly make a new plan.', weights: {'decisionMaking': 4, 'adaptability': 3}),
      CareerDnaOption(id: 'b', text: 'Take time to understand first.', weights: {'decisionMaking': 2, 'adaptability': 2, 'problemSolving': 2}),
      CareerDnaOption(id: 'c', text: 'Ask someone I trust what to do.', weights: {'decisionMaking': 1, 'socialOrientation': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'Go with it and see what happens.', weights: {'adaptability': 4, 'decisionMaking': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q6',
    text: 'Nobody has volunteered to organise an important group activity. Which response feels most natural?',
    options: [
      CareerDnaOption(id: 'a', text: 'Wait and see who steps up.', weights: {'leadershipInitiative': 1}),
      CareerDnaOption(id: 'b', text: 'Offer to help whoever leads.', weights: {'leadershipInitiative': 2, 'teamOrientation': 3}),
      CareerDnaOption(id: 'c', text: 'Suggest how to organise it.', weights: {'leadershipInitiative': 3, 'teamOrientation': 2, 'adaptability': 2}),
      CareerDnaOption(id: 'd', text: 'Take charge of coordinating it.', weights: {'leadershipInitiative': 4, 'teamOrientation': 2, 'adaptability': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q7',
    text: 'Someone strongly disagrees with your opinion during a discussion. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Explain my different view.', weights: {'communicationConfidence': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'b', text: 'Ask why they think differently.', weights: {'adaptability': 3, 'communicationConfidence': 2, 'learningAgility': 2}),
      CareerDnaOption(id: 'c', text: 'See if it changes my mind.', weights: {'adaptability': 4, 'decisionMaking': 2}),
      CareerDnaOption(id: 'd', text: 'Move the discussion forward.', weights: {'communicationConfidence': 2, 'teamOrientation': 3, 'decisionMaking': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q8',
    text: 'You prepared seriously for something important, but the outcome was much lower than expected. What would you most likely do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Look at what went wrong.', weights: {'learningAgility': 3, 'resilience': 2, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Take time before revisiting it.', weights: {'resilience': 3, 'learningAgility': 1}),
      CareerDnaOption(id: 'c', text: "Talk to someone who'd understand.", weights: {'resilience': 2, 'socialOrientation': 3}),
      CareerDnaOption(id: 'd', text: 'Change my strategy next time.', weights: {'learningAgility': 4, 'resilience': 3, 'ambitionGrowth': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q9',
    text: 'Your friends are planning a trip and everyone has different preferences. Which role would you naturally take?',
    options: [
      CareerDnaOption(id: 'a', text: 'Suggest places and activities.', weights: {'socialOrientation': 3, 'leadershipInitiative': 1, 'teamOrientation': 1}),
      CareerDnaOption(id: 'b', text: 'Handle the details and budget.', weights: {'problemSolving': 4, 'teamOrientation': 1}),
      CareerDnaOption(id: 'c', text: 'Find an option everyone enjoys.', weights: {'teamOrientation': 4, 'socialOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Let others decide, and adapt.', weights: {'adaptability': 4, 'teamOrientation': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q10',
    text: 'You get an opportunity to participate in something you have never tried before. What attracts you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Learning something new.', weights: {'learningAgility': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'b', text: 'Trying something new.', weights: {'adaptability': 4, 'learningAgility': 1}),
      CareerDnaOption(id: 'c', text: 'People I trust are involved.', weights: {'socialOrientation': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'Achieving something big.', weights: {'ambitionGrowth': 4, 'leadershipInitiative': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q11',
    text: 'A friend asks you for help while you are busy with your own work. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Help right away if important.', weights: {'teamOrientation': 4, 'decisionMaking': 1}),
      CareerDnaOption(id: 'b', text: 'Finish my task, then help them.', weights: {'decisionMaking': 3, 'teamOrientation': 2, 'leadershipInitiative': 1}),
      CareerDnaOption(id: 'c', text: 'Give a quick tip to help them.', weights: {'teamOrientation': 2, 'problemSolving': 2, 'decisionMaking': 2}),
      CareerDnaOption(id: 'd', text: 'Ask what they need first.', weights: {'decisionMaking': 4, 'teamOrientation': 2, 'problemSolving': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q12',
    text: 'You are suddenly asked to speak in front of a group without preparation. Which feels most like you?',
    options: [
      CareerDnaOption(id: 'a', text: 'Start speaking, think as I go.', weights: {'communicationConfidence': 4, 'adaptability': 3}),
      CareerDnaOption(id: 'b', text: 'Gather my thoughts first.', weights: {'communicationConfidence': 2, 'problemSolving': 2, 'adaptability': 1}),
      CareerDnaOption(id: 'c', text: 'Keep it short and to the point.', weights: {'communicationConfidence': 3, 'problemSolving': 2}),
      CareerDnaOption(id: 'd', text: 'Involve the audience in it.', weights: {'communicationConfidence': 3, 'socialOrientation': 3, 'adaptability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q13',
    text: 'You are stuck while trying to solve a difficult problem. What would you naturally try first?',
    options: [
      CareerDnaOption(id: 'a', text: 'Try a different approach.', weights: {'problemSolving': 3, 'adaptability': 4}),
      CareerDnaOption(id: 'b', text: 'Search for info or examples.', weights: {'problemSolving': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'c', text: "Ask someone who's faced this.", weights: {'teamOrientation': 3, 'socialOrientation': 2, 'problemSolving': 1}),
      CareerDnaOption(id: 'd', text: 'Step away, come back fresh.', weights: {'adaptability': 2, 'resilience': 3, 'problemSolving': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q14',
    text: 'Someone asks you to coordinate something important for a group. Which part would you naturally enjoy most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Decide how it should run.', weights: {'leadershipInitiative': 4, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Getting people involved.', weights: {'socialOrientation': 4, 'leadershipInitiative': 2, 'teamOrientation': 2}),
      CareerDnaOption(id: 'c', text: 'Solving unexpected issues.', weights: {'problemSolving': 4, 'adaptability': 2}),
      CareerDnaOption(id: 'd', text: 'Making sure details are right.', weights: {'problemSolving': 3, 'leadershipInitiative': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q15',
    text: 'You participate in a competition where several participants are much better than you. What would interest you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Testing myself against rivals.', weights: {'ambitionGrowth': 4, 'resilience': 2}),
      CareerDnaOption(id: 'b', text: 'Watching how the best do it.', weights: {'learningAgility': 4, 'ambitionGrowth': 1}),
      CareerDnaOption(id: 'c', text: 'Finding my own strategy.', weights: {'problemSolving': 3, 'ambitionGrowth': 2}),
      CareerDnaOption(id: 'd', text: 'Seeing how much I can improve.', weights: {'learningAgility': 3, 'ambitionGrowth': 3, 'resilience': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q16',
    text: 'You have two equally attractive choices and need to select one. What would you naturally rely on?',
    options: [
      CareerDnaOption(id: 'a', text: 'Information and facts.', weights: {'decisionMaking': 4, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Advice from people I trust.', weights: {'socialOrientation': 4, 'decisionMaking': 1}),
      CareerDnaOption(id: 'c', text: 'What feels right to me.', weights: {'decisionMaking': 2, 'adaptability': 2}),
      CareerDnaOption(id: 'd', text: 'Whichever opens more doors.', weights: {'ambitionGrowth': 4, 'decisionMaking': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q17',
    text: 'A person in your group is finding it difficult to complete their part of a project. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: "Ask what they're finding hard.", weights: {'teamOrientation': 4, 'socialOrientation': 2}),
      CareerDnaOption(id: 'b', text: 'Show them my approach.', weights: {'leadershipInitiative': 3, 'teamOrientation': 2, 'problemSolving': 2}),
      CareerDnaOption(id: 'c', text: 'Give them time to figure it out.', weights: {'adaptability': 2, 'teamOrientation': 1, 'leadershipInitiative': 1}),
      CareerDnaOption(id: 'd', text: "Adjust the plan as needed.", weights: {'leadershipInitiative': 3, 'adaptability': 3, 'teamOrientation': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q18',
    text: 'You unexpectedly get an entire day free. Which option sounds most appealing?',
    options: [
      CareerDnaOption(id: 'a', text: 'Meet friends, be social.', weights: {'socialOrientation': 4, 'teamOrientation': 1}),
      CareerDnaOption(id: 'b', text: 'Learn or explore something new.', weights: {'learningAgility': 4, 'socialOrientation': 1}),
      CareerDnaOption(id: 'c', text: 'Relax and do what I feel like.', weights: {'adaptability': 2, 'ambitionGrowth': 1}),
      CareerDnaOption(id: 'd', text: 'Work on something useful.', weights: {'ambitionGrowth': 4, 'learningAgility': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q19',
    text: "Something you were confident about doesn't work out. What would you naturally do?",
    options: [
      CareerDnaOption(id: 'a', text: 'Try to understand what happened.', weights: {'resilience': 3, 'learningAgility': 2}),
      CareerDnaOption(id: 'b', text: 'Take time to reset first.', weights: {'resilience': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'c', text: 'Talk to someone close to me.', weights: {'resilience': 2, 'socialOrientation': 4}),
      CareerDnaOption(id: 'd', text: 'Find another route to the goal.', weights: {'resilience': 3, 'ambitionGrowth': 3, 'adaptability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q20',
    text: 'Imagine yourself five years from now. Which situation would make you feel most satisfied?',
    options: [
      CareerDnaOption(id: 'a', text: 'Mastering something valuable.', weights: {'learningAgility': 4, 'ambitionGrowth': 2}),
      CareerDnaOption(id: 'b', text: 'Having more influence.', weights: {'leadershipInitiative': 4, 'ambitionGrowth': 2}),
      CareerDnaOption(id: 'c', text: 'A great network of people.', weights: {'socialOrientation': 4, 'teamOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'New opportunities to grow.', weights: {'adaptability': 4, 'learningAgility': 2, 'ambitionGrowth': 1}),
    ],
  ),
];

// naturalStyle strings are deliberately 3-4 sentence paragraphs, not one
// short line — per direct feedback, this is now the home for the "detailed
// persona" copy that used to live in a separate row of strength chips below
// the hero (see career_dna_report_screen.dart's _ArchetypeHero, which no
// longer renders those chips). Each paragraph weaves its own 4 `strengths`
// words into natural prose rather than dropping them as standalone badges —
// the `strengths` field itself stays populated/unused-by-this-screen, since
// Phase B's Level 5 synthesis may still want it as structured data.
const _archetypes = {
  'leader': CareerDnaArchetype(
    id: 'leader',
    name: 'The Leader',
    naturalStyle:
        "You take ownership naturally and step up when something needs direction — that's real initiative, not just confidence. You're comfortable being the one people look to, and you'd rather shape a decision than just wait for one. That decisiveness is what gives you influence: people trust your calls because you're willing to actually make them, even when the picture isn't fully clear.",
    growthAreaTitle: 'Listening & Collaboration',
    growthAreaText: 'Your instinct to take charge is a real strength — pairing it with a habit of drawing more out of quieter teammates before deciding will make your calls land even better.',
    strengths: ['Ownership', 'Initiative', 'Decisiveness', 'Influence'],
    environments: ['Management', 'Entrepreneurship', 'Operations', 'Project Leadership'],
  ),
  'connector': CareerDnaArchetype(
    id: 'connector',
    name: 'The Connector',
    naturalStyle:
        "You're genuinely energized by people — understanding them, bringing them together, and making sure everyone's actually heard. That's empathy and social awareness working together: you pick up on what a room needs before anyone says it out loud. Your communication style is what turns that awareness into real relationship-building, which is why rooms feel easier the moment you're in them.",
    growthAreaTitle: 'Structured Decision-Making',
    growthAreaText: "Your read on people is a real edge. Backing it with a bit more structure when a decision needs to move fast — not just consensus — will make that edge even sharper.",
    strengths: ['Communication', 'Empathy', 'Relationship-Building', 'Social Awareness'],
    environments: ['Sales', 'Marketing', 'HR', 'Client Management', 'Public Relations'],
  ),
  'strategist': CareerDnaArchetype(
    id: 'strategist',
    name: 'The Strategist',
    naturalStyle:
        'You think before you act, and it shows — you naturally break a problem down, weigh the real options, and land on a well-reasoned call rather than the first idea that shows up. That\'s genuine analytical thinking paired with real depth, not just caution. Your problem-solving holds up under pressure because your judgement is built on actually understanding a situation, not guessing at it.',
    growthAreaTitle: 'Confident Communication',
    growthAreaText: 'Your thinking is already sound — the next step is simply saying it with more conviction, sooner, so the room benefits from it before the decision is already made.',
    strengths: ['Analytical Thinking', 'Problem Solving', 'Judgement', 'Depth'],
    environments: ['Consulting', 'Research', 'Analytics', 'Strategy', 'Finance'],
  ),
  'explorer': CareerDnaArchetype(
    id: 'explorer',
    name: 'The Explorer',
    naturalStyle:
        "You tend to be curious, adaptable, and genuinely comfortable exploring new experiences rather than sticking to what's familiar. That curiosity is what fuels your learning — you pick things up fast because you're actually interested, not just going through the motions. You likely thrive in environments built around exploration, where every day looks a little different and your adaptability gets to actually matter.",
    growthAreaTitle: 'Structured Planning & Consistency',
    growthAreaText: 'Your profile suggests you enjoy variety and new experiences. Building a few stronger planning habits can help you convert that flexibility into consistent, compounding results.',
    strengths: ['Curiosity', 'Adaptability', 'Learning', 'Exploration'],
    environments: ['Startups', 'Marketing', 'Business Development', 'Consulting', 'Entrepreneurship'],
  ),
  'achiever': CareerDnaArchetype(
    id: 'achiever',
    name: 'The Achiever',
    naturalStyle:
        "You're driven by real, visible progress — setting a goal and pushing toward it is genuinely motivating for you. That ambition comes with real persistence: you don't just start strong, you follow through. Your goal orientation and resilience work together here too — setbacks tend to fuel your next attempt rather than stall you, which is a rarer combination than it sounds.",
    growthAreaTitle: 'Patience & Team Trust',
    growthAreaText: 'Your drive is a genuine asset. Slowing down just enough to bring others fully along — not only to move faster yourself — will multiply what that drive can achieve.',
    strengths: ['Ambition', 'Persistence', 'Goal Orientation', 'Resilience'],
    environments: ['Sales', 'Business Development', 'Consulting', 'Growth Roles', 'Entrepreneurship'],
  ),
  'builder': CareerDnaArchetype(
    id: 'builder',
    name: 'The Builder',
    naturalStyle:
        "You're the one things can actually be handed to — reliable, organised, and focused on genuinely finishing what you start, not just starting it. Your consistency is rare: while others lose momentum, you keep showing up with the same level of care. That combination of reliability and strong execution is what makes people trust you with things that actually matter.",
    growthAreaTitle: 'Comfort with Change',
    growthAreaText: "Your consistency is rare and valuable. Getting a little more comfortable with ambiguity — situations without a clear process yet — will open up even more of what you're capable of.",
    strengths: ['Reliability', 'Organisation', 'Consistency', 'Execution'],
    environments: ['Operations', 'Project Management', 'Engineering', 'Finance', 'Quality & Process'],
  ),
};

/// Weighted primary(x2)/secondary(x1) classifier — highest total wins, with
/// a deterministic tie-break by this fixed priority order (Leader first).
/// BUILDER's doc-defined traits ("reliable, organised, consistent,
/// execution-focused") don't map onto any single one of the 10 given
/// dimensions as cleanly as the other 5 archetypes do — Team Orientation +
/// Resilience is the closest approximation, flagged here for a second look
/// once real usage data exists.
const _classifierRules = [
  ('leader', 'leadershipInitiative', 'decisionMaking'),
  ('connector', 'socialOrientation', 'communicationConfidence'),
  ('strategist', 'problemSolving', 'decisionMaking'),
  ('explorer', 'adaptability', 'learningAgility'),
  ('achiever', 'ambitionGrowth', 'resilience'),
  ('builder', 'teamOrientation', 'resilience'),
];

CareerDnaArchetype _classifyArchetype(Map<String, int> scores) {
  var bestId = _classifierRules.first.$1;
  var bestScore = -1;
  for (final (id, primary, secondary) in _classifierRules) {
    final score = 2 * (scores[primary] ?? 0) + (scores[secondary] ?? 0);
    if (score > bestScore) {
      bestScore = score;
      bestId = id;
    }
  }
  return _archetypes[bestId]!;
}

CareerDnaLevel1Result computeCareerDnaLevel1Result(Map<String, String> answers) {
  final scores = normalizedDimensionScores(
    questions: careerDnaLevel1Questions,
    answers: answers,
    dimensions: careerDnaLevel1Dimensions,
  );
  return CareerDnaLevel1Result(
    dimensionScores: scores,
    archetype: _classifyArchetype(scores),
    completedAt: DateTime.now().toIso8601String(),
  );
}
