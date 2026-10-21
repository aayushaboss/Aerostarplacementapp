import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import '../../utils/career_dna_scoring.dart';

/// Level 4 — Employability & Workplace Readiness. 20 workplace-situational
/// questions, transcribed from the source doc, across 5 sections (Ownership
/// & Responsibility, Priorities & Time Management, Instructions & Quality,
/// Feedback & Professional Growth, Professional Judgement). Options are
/// trimmed to fit one line wherever reasonably possible.
const List<String> careerDnaLevel4Dimensions = [
  'ownership',
  'reliability',
  'prioritisation',
  'executionDiscipline',
  'attentionToDetail',
  'instructionManagement',
  'professionalJudgement',
  'feedbackOrientation',
  'adaptabilityAtWork',
  'continuousImprovement',
];

final List<CareerDnaQuestion> careerDnaLevel4Questions = [
  const CareerDnaQuestion(
    id: 'l4q1',
    text: "You're given a Friday deadline. By Wednesday you realise you underestimated the work and may not finish on time.",
    options: [
      CareerDnaOption(id: 'a', text: 'Work harder, hope to still finish Friday.', weights: {'reliability': 1, 'ownership': 1}),
      CareerDnaOption(id: 'b', text: 'Tell your manager early, propose a new plan.', weights: {'ownership': 4, 'professionalJudgement': 3, 'reliability': 2}),
      CareerDnaOption(id: 'c', text: 'Ask a colleague for help, quietly.', weights: {'adaptabilityAtWork': 2, 'ownership': 1}),
      CareerDnaOption(id: 'd', text: 'Only say something if you actually miss it.', weights: {'ownership': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q2',
    text: "You submit a report, then find a small error that doesn't change the conclusion.",
    options: [
      CareerDnaOption(id: 'a', text: 'Correct it silently in your own records.', weights: {'ownership': 1, 'attentionToDetail': 2}),
      CareerDnaOption(id: 'b', text: 'Wait to see if anyone notices.', weights: {'reliability': 1}),
      CareerDnaOption(id: 'c', text: 'Tell the relevant person, send a correction.', weights: {'ownership': 4, 'attentionToDetail': 3, 'professionalJudgement': 2}),
      CareerDnaOption(id: 'd', text: 'Mention it only if it becomes important.', weights: {'professionalJudgement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q3',
    text: 'A task is done, but the outcome is weaker than expected. Your first reaction would be:',
    options: [
      CareerDnaOption(id: 'a', text: 'Explain what affected the outcome.', weights: {'professionalJudgement': 2}),
      CareerDnaOption(id: 'b', text: 'Work out what you\'d do differently.', weights: {'continuousImprovement': 4, 'ownership': 2}),
      CareerDnaOption(id: 'c', text: 'Ask if the expectations were realistic.', weights: {'professionalJudgement': 2}),
      CareerDnaOption(id: 'd', text: 'Move on unless someone asks for a review.', weights: {'continuousImprovement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q4',
    text: "A process you've followed for weeks has an unnecessary step in it.",
    options: [
      CareerDnaOption(id: 'a', text: "Keep following it, that's how I was told.", weights: {'instructionManagement': 2}),
      CareerDnaOption(id: 'b', text: 'Remove the step myself, it saves time.', weights: {'continuousImprovement': 3, 'ownership': 2}),
      CareerDnaOption(id: 'c', text: 'Ask if the process can be improved.', weights: {'continuousImprovement': 4, 'professionalJudgement': 3}),
      CareerDnaOption(id: 'd', text: 'Mention it informally to a colleague.', weights: {'continuousImprovement': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q5',
    text: 'At 10 AM you have a report due at 1, a routine task due tomorrow, an urgent-but-open-ended manager request, and an email to answer.',
    options: [
      CareerDnaOption(id: 'a', text: "The manager's request, since it's from them.", weights: {'instructionManagement': 2}),
      CareerDnaOption(id: 'b', text: 'The report — closest deadline.', weights: {'prioritisation': 2}),
      CareerDnaOption(id: 'c', text: 'The email first, to clear my inbox.', weights: {'prioritisation': 1}),
      CareerDnaOption(id: 'd', text: 'Assess urgency and importance, then sequence all four.', weights: {'prioritisation': 4, 'professionalJudgement': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q6',
    text: 'Your manager gives you an urgent new task while you\'re mid-way through another important one.',
    options: [
      CareerDnaOption(id: 'a', text: 'Stop the old task immediately, start the new one.', weights: {'adaptabilityAtWork': 2, 'prioritisation': 1}),
      CareerDnaOption(id: 'b', text: 'Finish the old task first, unless told otherwise.', weights: {'reliability': 2, 'prioritisation': 2}),
      CareerDnaOption(id: 'c', text: 'Clarify priority and deadlines before switching.', weights: {'prioritisation': 4, 'professionalJudgement': 3, 'instructionManagement': 2}),
      CareerDnaOption(id: 'd', text: 'Try to work on both at once.', weights: {'prioritisation': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q7',
    text: 'Two hours left in the day, three incomplete tasks: one nearly done, one due tomorrow, one important with no set deadline.',
    options: [
      CareerDnaOption(id: 'a', text: 'Finish the one that\'s nearly done.', weights: {'executionDiscipline': 2}),
      CareerDnaOption(id: 'b', text: 'Work on the one due soonest.', weights: {'prioritisation': 2}),
      CareerDnaOption(id: 'c', text: 'Weigh deadline, importance, effort and consequences.', weights: {'prioritisation': 4, 'professionalJudgement': 3}),
      CareerDnaOption(id: 'd', text: 'Ask my manager which one to do.', weights: {'instructionManagement': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q8',
    text: 'Small requests keep interrupting your planned work through the day.',
    options: [
      CareerDnaOption(id: 'a', text: 'Handle each one right away.', weights: {'prioritisation': 1}),
      CareerDnaOption(id: 'b', text: 'Ignore them, stay on planned work.', weights: {'adaptabilityAtWork': 1}),
      CareerDnaOption(id: 'c', text: 'Batch the non-urgent ones around priority work.', weights: {'prioritisation': 4, 'executionDiscipline': 2, 'adaptabilityAtWork': 2}),
      CareerDnaOption(id: 'd', text: 'Ask people to stop sending them for now.', weights: {'professionalJudgement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q9',
    text: 'Detailed instructions from your manager, but one part is unclear — the rest is straightforward.',
    options: [
      CareerDnaOption(id: 'a', text: 'Make my own assumption, keep going.', weights: {'instructionManagement': 1}),
      CareerDnaOption(id: 'b', text: 'Ask about the unclear part before starting.', weights: {'instructionManagement': 4, 'professionalJudgement': 3}),
      CareerDnaOption(id: 'c', text: 'Finish what I understand, skip the rest.', weights: {'instructionManagement': 2}),
      CareerDnaOption(id: 'd', text: 'Search for how similar tasks are usually done.', weights: {'instructionManagement': 2, 'continuousImprovement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q10',
    text: "You're given a task you've never done before.",
    options: [
      CareerDnaOption(id: 'a', text: 'Try it myself, learn as I go.', weights: {'adaptabilityAtWork': 3, 'ownership': 2}),
      CareerDnaOption(id: 'b', text: 'Ask someone to explain the whole process first.', weights: {'instructionManagement': 2}),
      CareerDnaOption(id: 'c', text: 'Understand the goal, review guidance, ask what I need.', weights: {'instructionManagement': 4, 'professionalJudgement': 3, 'ownership': 2}),
      CareerDnaOption(id: 'd', text: 'Wait for a detailed step-by-step process.', weights: {'instructionManagement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q11',
    text: 'You finish a task earlier than expected.',
    options: [
      CareerDnaOption(id: 'a', text: 'Submit right away, move on.', weights: {'executionDiscipline': 1}),
      CareerDnaOption(id: 'b', text: 'Review the work carefully first.', weights: {'attentionToDetail': 4, 'executionDiscipline': 3}),
      CareerDnaOption(id: 'c', text: 'Ask for another task.', weights: {'ownership': 3, 'executionDiscipline': 2}),
      CareerDnaOption(id: 'd', text: 'Use the extra time for something unrelated.', weights: {'reliability': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q12',
    text: 'An important document you\'re working on conflicts with an older document.',
    options: [
      CareerDnaOption(id: 'a', text: 'Follow the newer instructions.', weights: {'instructionManagement': 2}),
      CareerDnaOption(id: 'b', text: 'Follow the older one — it\'s been used before.', weights: {'instructionManagement': 1}),
      CareerDnaOption(id: 'c', text: 'Clarify which should take priority first.', weights: {'instructionManagement': 4, 'professionalJudgement': 4, 'attentionToDetail': 2}),
      CareerDnaOption(id: 'd', text: 'Use whichever seems more practical.', weights: {'professionalJudgement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q13',
    text: '"The result is acceptable, but your approach needs work" — your manager\'s review. You disagree somewhat.',
    options: [
      CareerDnaOption(id: 'a', text: 'Explain why I chose that approach.', weights: {'feedbackOrientation': 2}),
      CareerDnaOption(id: 'b', text: 'Ask what specifically could be better.', weights: {'feedbackOrientation': 4, 'continuousImprovement': 3}),
      CareerDnaOption(id: 'c', text: 'Accept it, change my approach next time.', weights: {'feedbackOrientation': 3, 'adaptabilityAtWork': 2}),
      CareerDnaOption(id: 'd', text: 'Keep my approach unless told specifically to change.', weights: {'feedbackOrientation': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q14',
    text: 'You get the same piece of feedback for the second time.',
    options: [
      CareerDnaOption(id: 'a', text: 'Ask for a specific example to understand it.', weights: {'feedbackOrientation': 4, 'continuousImprovement': 2}),
      CareerDnaOption(id: 'b', text: 'Make a real effort to change the behaviour.', weights: {'feedbackOrientation': 3, 'continuousImprovement': 3}),
      CareerDnaOption(id: 'c', text: "Feel frustrated — I've heard it already.", weights: {'feedbackOrientation': 1}),
      CareerDnaOption(id: 'd', text: 'Explain why it keeps happening.', weights: {'feedbackOrientation': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q15',
    text: 'A senior colleague gives advice that differs from what your manager told you earlier.',
    options: [
      CareerDnaOption(id: 'a', text: 'Follow the senior colleague — more experience.', weights: {'instructionManagement': 1}),
      CareerDnaOption(id: 'b', text: "Follow my manager's original instruction.", weights: {'instructionManagement': 2, 'reliability': 2}),
      CareerDnaOption(id: 'c', text: 'Clarify the difference before deciding.', weights: {'professionalJudgement': 4, 'instructionManagement': 3}),
      CareerDnaOption(id: 'd', text: 'Go with whichever seems easier.', weights: {'professionalJudgement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q16',
    text: "You're asked to take on a responsibility outside what you originally expected from your role.",
    options: [
      CareerDnaOption(id: 'a', text: 'Accept it without question.', weights: {'adaptabilityAtWork': 2}),
      CareerDnaOption(id: 'b', text: "Ask why, and what's expected.", weights: {'professionalJudgement': 3, 'instructionManagement': 3, 'adaptabilityAtWork': 2}),
      CareerDnaOption(id: 'c', text: "Decline — it wasn't part of my role.", weights: {'adaptabilityAtWork': 1}),
      CareerDnaOption(id: 'd', text: "Accept it, but note it's outside my usual scope.", weights: {'adaptabilityAtWork': 3, 'ownership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q17',
    text: 'Working remotely, you finish two hours early with nothing else assigned.',
    options: [
      CareerDnaOption(id: 'a', text: "Log off — my assigned work is done.", weights: {'reliability': 1}),
      CareerDnaOption(id: 'b', text: 'Stay available, look for useful pending work.', weights: {'ownership': 4, 'professionalJudgement': 3, 'reliability': 2}),
      CareerDnaOption(id: 'c', text: 'Message my manager to ask about logging off.', weights: {'professionalJudgement': 2, 'instructionManagement': 2}),
      CareerDnaOption(id: 'd', text: 'Spend the rest of the time on personal stuff.', weights: {'reliability': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q18',
    text: 'You accidentally receive an internal document clearly not meant for you.',
    options: [
      CareerDnaOption(id: 'a', text: "Read it, since it already reached me.", weights: {'professionalJudgement': 1}),
      CareerDnaOption(id: 'b', text: 'Ignore it, leave it in my inbox.', weights: {'professionalJudgement': 2}),
      CareerDnaOption(id: 'c', text: "Tell the sender, avoid reading further.", weights: {'professionalJudgement': 4, 'ownership': 2}),
      CareerDnaOption(id: 'd', text: 'Forward it to a colleague to ask about it.', weights: {'professionalJudgement': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q19',
    text: "You're running late for work and will miss an important meeting.",
    options: [
      CareerDnaOption(id: 'a', text: "Join once I reach the office.", weights: {'reliability': 1}),
      CareerDnaOption(id: 'b', text: 'Tell the relevant person as soon as I know.', weights: {'reliability': 4, 'ownership': 3, 'professionalJudgement': 2}),
      CareerDnaOption(id: 'c', text: 'Ask a colleague to explain my absence.', weights: {'reliability': 1}),
      CareerDnaOption(id: 'd', text: 'Attend later, explain if I\'m asked.', weights: {'reliability': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l4q20',
    text: 'Six months into your first job — good performance, but still the same small mistakes as when you joined.',
    options: [
      CareerDnaOption(id: 'a', text: "They're small — not a major concern.", weights: {'continuousImprovement': 1}),
      CareerDnaOption(id: 'b', text: 'Work on reducing them, find out why they happen.', weights: {'continuousImprovement': 4, 'attentionToDetail': 3}),
      CareerDnaOption(id: 'c', text: 'Ask my manager to review my work more often.', weights: {'continuousImprovement': 2, 'feedbackOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Work faster, despite the mistakes.', weights: {'continuousImprovement': 1}),
    ],
  ),
];

class _WorkStyle {
  final String title;
  final String text;
  const _WorkStyle({required this.title, required this.text});
}

const _workStyles = {
  'ownership': _WorkStyle(title: 'High Ownership / Self-Starter', text: 'You tend to take responsibility for outcomes, not just tasks — when something needs to happen, you naturally step in to make it happen.'),
  'reliability': _WorkStyle(title: 'Dependable & Consistent', text: "You're the kind of person a manager can count on to follow through — consistent, dependable, and rarely need a reminder."),
  'prioritisation': _WorkStyle(title: 'Sharp Prioritiser', text: 'You naturally read a busy day and work out what actually matters first, instead of just working a list top to bottom.'),
  'executionDiscipline': _WorkStyle(title: 'Structured Executor', text: 'You bring real structure to how you work — methodical, systematic, and unlikely to leave things half-finished.'),
  'attentionToDetail': _WorkStyle(title: 'Detail-Focused', text: "You notice the small things others miss, and you'd rather double-check than let an error slip through."),
  'instructionManagement': _WorkStyle(title: 'Clarity-Seeker', text: 'You ask the right clarifying questions before diving in, rather than guessing and hoping it works out.'),
  'professionalJudgement': _WorkStyle(title: 'Sound Judgement', text: "You read ambiguous workplace situations well, and tend to make sound calls even when there's no clear rulebook."),
  'feedbackOrientation': _WorkStyle(title: 'Fast Learner From Feedback', text: 'You take feedback seriously and actually act on it — a genuinely valuable trait this early in a career.'),
  'adaptabilityAtWork': _WorkStyle(title: 'Adaptable Operator', text: "You adjust smoothly when priorities shift or a role asks something new of you, rather than getting thrown off."),
  'continuousImprovement': _WorkStyle(title: 'Improvement-Minded', text: "You notice when something could work better, and you're usually the one who goes and actually fixes it."),
};

const _developmentAreas = {
  'ownership': _WorkStyle(title: 'Taking Initiative Earlier', text: 'Speaking up and taking ownership a little sooner — before being asked — is a habit that compounds fast once it starts.'),
  'reliability': _WorkStyle(title: 'Building Consistency', text: "Being someone people can set their clock by is a skill, not a personality trait — a few deliberate habits will get you there."),
  'prioritisation': _WorkStyle(title: 'Sharpening Prioritisation', text: "As your workload grows, getting quicker at spotting what's truly urgent versus just noisy will save real time."),
  'executionDiscipline': _WorkStyle(title: 'Structured Follow-Through', text: 'Building a simple system for tracking work end-to-end will make your natural effort show up more consistently.'),
  'attentionToDetail': _WorkStyle(title: 'Slowing Down to Check', text: 'A quick second pass before submitting anything is a small habit that prevents most avoidable mistakes.'),
  'instructionManagement': _WorkStyle(title: 'Asking Sooner', text: 'Asking a clarifying question earlier — before getting deep into the work — saves rework later on.'),
  'professionalJudgement': _WorkStyle(title: 'Trusting Your Judgement', text: 'You already have good instincts here — leaning on them a little more confidently in ambiguous moments will serve you well.'),
  'feedbackOrientation': _WorkStyle(title: 'Turning Feedback Into Action', text: 'Treating repeated feedback as a signal worth acting on, not just hearing, is what turns feedback into real growth.'),
  'adaptabilityAtWork': _WorkStyle(title: 'Flexing With Change', text: 'Workplaces shift constantly — getting more comfortable adjusting on short notice will make it feel less disruptive.'),
  'continuousImprovement': _WorkStyle(title: 'Spotting Repeat Patterns', text: 'Noticing when the same small issue keeps showing up — and asking why — is a habit worth building deliberately.'),
};

const _priorityOrder = [
  'ownership', 'reliability', 'prioritisation', 'executionDiscipline', 'attentionToDetail',
  'instructionManagement', 'professionalJudgement', 'feedbackOrientation', 'adaptabilityAtWork', 'continuousImprovement',
];

/// Doc-given thresholds — all four bands are written to read encouragingly,
/// including the lowest, per this app's explicit optimism requirement (see
/// the plan). Never a verdict, always "where you're starting from."
String _bandFor(int overall) {
  if (overall >= 90) return 'highlyReady';
  if (overall >= 75) return 'workplaceReady';
  if (overall >= 60) return 'developingReadiness';
  return 'preparationRequired';
}

const careerDnaWorkplaceReadinessBandCopy = {
  'highlyReady': "You're already showing strong professional judgement and real workplace discipline.",
  'workplaceReady': "You've got a strong foundation, with a couple of clear, manageable areas to keep building.",
  'developingReadiness': "You're showing real potential — a bit of structured practice will take you a long way.",
  'preparationRequired': "You're right at the start of building these habits, and that's a completely normal place to be — focused practice from here builds real readiness fast.",
};

CareerDnaLevel4Result computeCareerDnaLevel4Result(Map<String, String> answers) {
  final scores = normalizedDimensionScores(
    questions: careerDnaLevel4Questions,
    answers: answers,
    dimensions: careerDnaLevel4Dimensions,
  );

  final overall = (scores.values.fold<int>(0, (a, b) => a + b) / scores.length).round();

  var topDim = _priorityOrder.first;
  var topScore = -1;
  var bottomDim = _priorityOrder.first;
  var bottomScore = 101;
  for (final d in _priorityOrder) {
    final s = scores[d] ?? 0;
    if (s > topScore) {
      topScore = s;
      topDim = d;
    }
    if (s < bottomScore) {
      bottomScore = s;
      bottomDim = d;
    }
  }

  final style = _workStyles[topDim]!;
  final growth = _developmentAreas[bottomDim]!;

  return CareerDnaLevel4Result(
    dimensionScores: scores,
    overallReadiness: overall,
    band: _bandFor(overall),
    workStyleTitle: style.title,
    workStyleText: style.text,
    developmentAreaTitle: growth.title,
    developmentAreaText: growth.text,
    completedAt: DateTime.now().toIso8601String(),
  );
}

/// Phrase per dimension for the report screen's narrative snapshot.
const careerDnaLevel4DimensionPhrases = {
  'ownership': 'taking real responsibility for outcomes',
  'reliability': 'being someone people can count on',
  'prioritisation': 'telling what actually matters first',
  'executionDiscipline': 'following through on work systematically',
  'attentionToDetail': 'catching the small things others miss',
  'instructionManagement': 'asking the right clarifying questions',
  'professionalJudgement': 'making sound calls in grey areas',
  'feedbackOrientation': 'turning feedback into real change',
  'adaptabilityAtWork': 'adjusting when priorities shift',
  'continuousImprovement': 'fixing recurring problems, not just tolerating them',
};
