import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import '../../utils/career_dna_scoring.dart';

/// Level 5 — Career Mapping. 20 questions transcribed from the source doc,
/// across 5 sections (Discovering Work Preference, Job Environment Fit,
/// Career Scenarios, Career Trade-offs, Role Discovery). Section 4 (Q13-16)
/// uses the doc's own forced-choice format: a real A/B trade-off plus two
/// marked hedge options (**C/**D) that deliberately carry no dimension
/// weight at all — picking a hedge is a legitimate answer, it just adds no
/// signal either way, exactly the anti-gaming device the source doc calls
/// out for this level.
///
/// Per the doc, Level 5 is explicitly NOT scored in isolation — see
/// computeCareerDnaLevel5Result below, which blends this level's own 20-
/// question score with a cross-test-mapped score built from Levels 1-4's
/// already-computed results.
const List<String> careerDnaLevel5Dimensions = [
  'analyticalData',
  'technologyProduct',
  'peopleClient',
  'salesBusinessDevelopment',
  'creativeMedia',
  'managementLeadership',
  'operations',
  'entrepreneurial',
];

final List<CareerDnaQuestion> careerDnaLevel5Questions = [
  const CareerDnaQuestion(
    id: 'l5q1',
    text: 'A one-week project — you can choose which part to own. Which would you prefer?',
    options: [
      CareerDnaOption(id: 'a', text: 'Study the info, find patterns, conclude.', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: 'Speak to users, understand what they need.', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: 'Develop the concept or creative direction.', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: 'Coordinate it and see it through.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q2',
    text: 'A company asks you to improve one of its products. Which assignment interests you most?',
    options: [
      CareerDnaOption(id: 'a', text: "Analyse data — what's working, what isn't.", weights: {'analyticalData': 4, 'technologyProduct': 2}),
      CareerDnaOption(id: 'b', text: 'Interview customers about their problems.', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: 'Think of new features or a fresh experience.', weights: {'creativeMedia': 3, 'technologyProduct': 2}),
      CareerDnaOption(id: 'd', text: 'Coordinate teams to implement the fix.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q3',
    text: 'You are offered four short-term projects. Which one would you choose?',
    options: [
      CareerDnaOption(id: 'a', text: "Analyse why a business is losing customers.", weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: 'Build relationships with 50 potential clients.', weights: {'salesBusinessDevelopment': 4, 'peopleClient': 2}),
      CareerDnaOption(id: 'c', text: 'Create a campaign to launch a new brand.', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: 'Manage the execution of a major event.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q4',
    text: 'Which type of workday sounds most satisfying?',
    options: [
      CareerDnaOption(id: 'a', text: 'Focused analysis, then presenting findings.', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: 'Conversations, meetings, different people.', weights: {'peopleClient': 3, 'salesBusinessDevelopment': 2}),
      CareerDnaOption(id: 'c', text: 'Flexible — developing ideas, creating.', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: 'Fast-moving, coordinating, solving issues.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q5',
    text: 'Comparing four first-job environments — which sounds most attractive?',
    options: [
      CareerDnaOption(id: 'a', text: 'Structured, detailed, measurable accuracy.', weights: {'operations': 4, 'analyticalData': 2}),
      CareerDnaOption(id: 'b', text: 'Fast-moving, client contact, targets.', weights: {'salesBusinessDevelopment': 4, 'peopleClient': 2}),
      CareerDnaOption(id: 'c', text: 'Flexible, experimentation, freedom.', weights: {'creativeMedia': 4, 'entrepreneurial': 2}),
      CareerDnaOption(id: 'd', text: 'Cross-functional, multiple teams.', weights: {'managementLeadership': 4, 'operations': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q6',
    text: '"Don\'t just follow the process — find a better way," says your manager. Which assignment would you enjoy most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Investigating why the process is inefficient.', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: 'Understanding how users experience it.', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: 'Designing a completely new approach.', weights: {'creativeMedia': 4, 'technologyProduct': 2}),
      CareerDnaOption(id: 'd', text: 'Implementing the improved process.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q7',
    text: 'Which work environment would you find hardest to enjoy?',
    options: [
      CareerDnaOption(id: 'a', text: 'Little chance to analyse things deeply.', weights: {'analyticalData': 3}),
      CareerDnaOption(id: 'b', text: 'Mostly independent, minimal interaction.', weights: {'peopleClient': 3}),
      CareerDnaOption(id: 'c', text: 'Repetitive, little room for new ideas.', weights: {'creativeMedia': 3}),
      CareerDnaOption(id: 'd', text: 'Responsibility with little real influence.', weights: {'managementLeadership': 3, 'entrepreneurial': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q8',
    text: 'Specialise deeply in one area, or rotate across several business functions?',
    options: [
      CareerDnaOption(id: 'a', text: 'Become highly specialised in one area.', weights: {'analyticalData': 2, 'technologyProduct': 1}),
      CareerDnaOption(id: 'b', text: 'Work across areas, see how they connect.', weights: {'managementLeadership': 3, 'operations': 2}),
      CareerDnaOption(id: 'c', text: 'Move toward experimenting across work types.', weights: {'creativeMedia': 3, 'entrepreneurial': 2}),
      CareerDnaOption(id: 'd', text: 'Rotate, aiming to manage bigger scope later.', weights: {'managementLeadership': 4, 'entrepreneurial': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q9',
    text: "Sales have fallen 20% — you're on the team investigating. Which part would you want?",
    options: [
      CareerDnaOption(id: 'a', text: 'Analyse the sales data, find where it dropped.', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: "Talk to customers and salespeople directly.", weights: {'peopleClient': 4, 'salesBusinessDevelopment': 2}),
      CareerDnaOption(id: 'c', text: 'Develop new ideas to attract customers.', weights: {'creativeMedia': 3, 'salesBusinessDevelopment': 2}),
      CareerDnaOption(id: 'd', text: 'Build and run a plan to recover sales.', weights: {'managementLeadership': 3, 'operations': 2, 'entrepreneurial': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q10',
    text: 'A new mobile app is launching. Which responsibility interests you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Track usage, see which features win.', weights: {'analyticalData': 4, 'technologyProduct': 2}),
      CareerDnaOption(id: 'b', text: 'Understand users, build real adoption.', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: 'Shape the product experience and story.', weights: {'creativeMedia': 3, 'technologyProduct': 2}),
      CareerDnaOption(id: 'd', text: 'Coordinate the launch across teams.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q11',
    text: 'A company wants to enter a new market. Which question interests you most?',
    options: [
      CareerDnaOption(id: 'a', text: '"What does the data tell us?"', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: '"What do customers here actually want?"', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: '"What could we create that stands out?"', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: '"How do we enter and grow here?"', weights: {'entrepreneurial': 4, 'salesBusinessDevelopment': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q12',
    text: "You're given a problem with no established solution. Which role would you rather play?",
    options: [
      CareerDnaOption(id: 'a', text: 'Research and understand it deeply.', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: 'Talk to the people it actually affects.', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: 'Generate unconventional solutions.', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: 'Turn the best solution into a real plan.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  CareerDnaQuestion(
    id: 'l5q13',
    text: 'Job A: high salary, structured, predictable, limited variety. Job B: slightly lower salary, fast-changing, real variety. Which would you prefer?',
    forcedChoice: true,
    options: const [
      CareerDnaOption(id: 'a', text: 'Job A.', weights: {'operations': 3, 'analyticalData': 1}),
      CareerDnaOption(id: 'b', text: 'Job B.', weights: {'entrepreneurial': 3, 'creativeMedia': 1}),
      CareerDnaOption(id: 'c', text: 'Depends on the actual role and future.', weights: {}),
      CareerDnaOption(id: 'd', text: "I'd compare learning and growth potential.", weights: {}),
    ],
  ),
  CareerDnaQuestion(
    id: 'l5q14',
    text: 'Role A: mostly independent, becoming a specialist. Role B: across multiple teams, broader but less specialised. Which appeals more?',
    forcedChoice: true,
    options: const [
      CareerDnaOption(id: 'a', text: 'Role A.', weights: {'analyticalData': 3}),
      CareerDnaOption(id: 'b', text: 'Role B.', weights: {'managementLeadership': 3}),
      CareerDnaOption(id: 'c', text: 'A balance between both.', weights: {}),
      CareerDnaOption(id: 'd', text: 'Whichever gives stronger long-term options.', weights: {}),
    ],
  ),
  CareerDnaQuestion(
    id: 'l5q15',
    text: 'Path A: stable, clearly defined responsibilities. Path B: less predictable, could grow fast if the business succeeds. Which would you choose?',
    forcedChoice: true,
    options: const [
      CareerDnaOption(id: 'a', text: 'Path A.', weights: {'operations': 3}),
      CareerDnaOption(id: 'b', text: 'Path B.', weights: {'entrepreneurial': 4}),
      CareerDnaOption(id: 'c', text: "I'd need more information first.", weights: {}),
      CareerDnaOption(id: 'd', text: "I'd weigh the risk against the upside.", weights: {}),
    ],
  ),
  CareerDnaQuestion(
    id: 'l5q16',
    text: 'A famous company in a role that bores you, or a lesser-known company in a role that genuinely interests you. Which would you prefer?',
    forcedChoice: true,
    options: const [
      CareerDnaOption(id: 'a', text: 'The famous company.', weights: {'managementLeadership': 1}),
      CareerDnaOption(id: 'b', text: 'The role that interests me.', weights: {'entrepreneurial': 3}),
      CareerDnaOption(id: 'c', text: "I'd compare the actual responsibilities.", weights: {}),
      CareerDnaOption(id: 'd', text: 'Whichever builds the stronger career profile.', weights: {}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q17',
    text: 'Which assignment would you be most willing to spend six months on?',
    options: [
      CareerDnaOption(id: 'a', text: 'Building reports, finding insights in data.', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: 'Managing customers and relationships.', weights: {'peopleClient': 4, 'salesBusinessDevelopment': 2}),
      CareerDnaOption(id: 'c', text: 'Developing campaigns or creative content.', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: 'Managing processes and execution.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q18',
    text: 'A startup lets you choose your first responsibility. Which would you pick?',
    options: [
      CareerDnaOption(id: 'a', text: 'Product / Data.', weights: {'technologyProduct': 3, 'analyticalData': 2}),
      CareerDnaOption(id: 'b', text: 'Sales / Business Development.', weights: {'salesBusinessDevelopment': 4}),
      CareerDnaOption(id: 'c', text: 'Marketing / Creative.', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: 'Operations / Business Management.', weights: {'operations': 4, 'managementLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q19',
    text: "Five years from now, exceptionally good at one thing — what would you want people to say?",
    options: [
      CareerDnaOption(id: 'a', text: '"Give them a hard problem — they\'ll solve it."', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: '"They build genuinely strong relationships."', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: '"They come up with ideas nobody else does."', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: '"When they own something, it gets done."', weights: {'managementLeadership': 4, 'operations': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l5q20',
    text: 'Your ideal first job — but you can pick only ONE of these. Which matters most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Intellectual challenge.', weights: {'analyticalData': 4}),
      CareerDnaOption(id: 'b', text: 'Human interaction.', weights: {'peopleClient': 4}),
      CareerDnaOption(id: 'c', text: 'Creative freedom.', weights: {'creativeMedia': 4}),
      CareerDnaOption(id: 'd', text: 'Ownership and impact.', weights: {'managementLeadership': 3, 'entrepreneurial': 3}),
    ],
  ),
];

class _DirectionInfo {
  final String label;
  final List<String> roles;
  const _DirectionInfo({required this.label, required this.roles});
}

const _directions = {
  'analyticalData': _DirectionInfo(label: 'Data & Business Analytics', roles: ['Business Analyst', 'Data Analyst', 'Operations Analyst']),
  'technologyProduct': _DirectionInfo(label: 'Technology & Product', roles: ['Product Analyst', 'Technical Associate', 'Systems Analyst']),
  'peopleClient': _DirectionInfo(label: 'People & Client Relations', roles: ['Client Success Associate', 'Account Manager', 'HR Associate']),
  'salesBusinessDevelopment': _DirectionInfo(label: 'Sales & Business Development', roles: ['Business Development Associate', 'Sales Executive', 'Growth Associate']),
  'creativeMedia': _DirectionInfo(label: 'Creative & Media', roles: ['Content Strategist', 'Brand Associate', 'Creative Associate']),
  'managementLeadership': _DirectionInfo(label: 'Management & Leadership', roles: ['Management Trainee', 'Program Associate', 'Project Coordinator']),
  'operations': _DirectionInfo(label: 'Operations & Execution', roles: ['Operations Analyst', 'Process Associate', 'Operations Coordinator']),
  'entrepreneurial': _DirectionInfo(label: 'Entrepreneurship & Growth', roles: ["Founder's Office Associate", 'Venture Associate', 'Growth Associate']),
};

class _NextStepsPack {
  final List<String> strengths;
  final List<String> developmentAreas;
  final List<String> nextSteps;
  const _NextStepsPack({required this.strengths, required this.developmentAreas, required this.nextSteps});
}

// Development areas are deliberately shorter than strengths (2 vs 4) — per
// this app's own optimism rule, the list of what's "still building" should
// never outweigh the list of what's already working.
const _packs = {
  'analyticalData': _NextStepsPack(
    strengths: ['Analytical thinking', 'Structured problem-solving', 'Comfort with data and evidence', 'A real learning orientation'],
    developmentAreas: ['Communicating findings persuasively', 'Moving faster through ambiguous data'],
    nextSteps: ['Excel/SQL fundamentals', 'A recognised data-analytics certification', 'A real analysis project, written up publicly', 'A data or business-analyst internship', 'Business Analyst / Data Analyst role'],
  ),
  'technologyProduct': _NextStepsPack(
    strengths: ['Systems thinking', 'Curiosity about how things are built', 'Comfort with technical detail', 'Solving problems within real constraints'],
    developmentAreas: ['Explaining technical work to non-technical people', 'Broader product and business context'],
    nextSteps: ['Core programming/product fundamentals', 'A relevant technical certification', 'A shipped personal or open-source project', 'A product/tech internship', 'Product Analyst / Associate Product role'],
  ),
  'peopleClient': _NextStepsPack(
    strengths: ['Reading people and situations well', 'Building trust quickly', 'Clear, warm communication', 'Genuine relationship-building'],
    developmentAreas: ['Structured decision-making under pressure', 'Comfort pushing back when it matters'],
    nextSteps: ['Client-communication fundamentals', 'A CRM or client-success certification', 'A real client-facing project or role', 'A client-success or HR internship', 'Client Success / Account Management role'],
  ),
  'salesBusinessDevelopment': _NextStepsPack(
    strengths: ['Influence without needing authority', 'Comfort with commercial conversations', 'Resilience through rejection', 'Genuinely growth-oriented thinking'],
    developmentAreas: ['Deeper product and market knowledge', 'Structured pipeline and follow-up habits'],
    nextSteps: ['Sales and negotiation fundamentals', 'A business-development certification', 'A real outreach or sales project', 'A BD or sales internship', 'Business Development Associate role'],
  ),
  'creativeMedia': _NextStepsPack(
    strengths: ['Original thinking', 'Comfort with ambiguity and iteration', 'A strong sense for what resonates', 'Genuine creative range'],
    developmentAreas: ['Tying creative work to measurable outcomes', 'Working well within tighter constraints'],
    nextSteps: ['Design or content fundamentals', 'A portfolio-building certification', 'A real, published creative project', 'A content or design internship', 'Creative Associate / Content role'],
  ),
  'managementLeadership': _NextStepsPack(
    strengths: ['Taking ownership naturally', 'Coordinating people toward a goal', 'Clear decision-making', 'Genuine comfort with responsibility'],
    developmentAreas: ['Delegating instead of doing it all yourself', 'Patience with slower-moving stakeholders'],
    nextSteps: ['Project-management fundamentals', 'A PM or leadership certification', 'A real cross-functional project you led', 'A management-trainee internship', 'Management Trainee / Program Associate role'],
  ),
  'operations': _NextStepsPack(
    strengths: ['Execution discipline', 'Genuine process-mindedness', 'Reliability under real deadlines', 'Attention to detail'],
    developmentAreas: ['Comfort with ambiguity when no process exists yet', 'Communicating change to a wider team'],
    nextSteps: ['Operations and process fundamentals', 'An operations-focused certification', 'A real process-improvement project', 'An operations internship', 'Operations Analyst / Associate role'],
  ),
  'entrepreneurial': _NextStepsPack(
    strengths: ['Comfort with risk and ambiguity', 'Spotting real opportunities early', 'A genuine bias toward action', 'Resilience through setbacks'],
    developmentAreas: ['Structured planning alongside the instinct to move fast', 'Bringing others along, not just moving solo'],
    nextSteps: ['Business-fundamentals grounding', 'An entrepreneurship or startup certification', 'A real early-stage project or venture', 'A startup internship', "Founder's Office / Startup Generalist role"],
  ),
};

const _priorityOrder = [
  'analyticalData', 'technologyProduct', 'peopleClient', 'salesBusinessDevelopment',
  'creativeMedia', 'managementLeadership', 'operations', 'entrepreneurial',
];

/// Level 5 is deliberately NOT scored in isolation — this cross-references
/// Levels 1-4's own already-computed dimension scores, per the source
/// doc's explicit "Test 5 is the validation layer" design. Each L5 target
/// dimension is a weighted average of several source dimensions from
/// earlier levels (weights don't need to pre-sum to 1 — computed as a
/// proper weighted average below, which normalizes automatically).
Map<String, int> _crossTestMappedScores(CareerDnaProfile profile) {
  int l1(String d) => profile.level1?.dimensionScores[d] ?? 0;
  int l2(String d) => profile.level2?.dimensionScores[d] ?? 0;
  int l3(String d) => profile.level3?.dimensionScores[d] ?? 0;
  int l4(String d) => profile.level4?.dimensionScores[d] ?? 0;

  int wavg(List<(int, double)> parts) {
    final totalWeight = parts.fold<double>(0, (a, p) => a + p.$2);
    if (totalWeight == 0) return 0;
    final sum = parts.fold<double>(0, (a, p) => a + p.$1 * p.$2);
    return (sum / totalWeight).round().clamp(0, 100);
  }

  return {
    'analyticalData': wavg([(l1('problemSolving'), 0.5), (l1('learningAgility'), 0.2), (l2('analytical'), 0.6), (l2('technology'), 0.2)]),
    'technologyProduct': wavg([(l2('technology'), 0.6), (l2('analytical'), 0.2), (l1('problemSolving'), 0.2)]),
    'peopleClient': wavg([(l2('peopleSocial'), 0.5), (l3('collaboration'), 0.4), (l3('socialAwareness'), 0.3)]),
    'salesBusinessDevelopment': wavg([(l2('entrepreneurialDrive'), 0.4), (l2('businessLeadership'), 0.3), (l3('influence'), 0.3)]),
    'creativeMedia': wavg([(l2('creative'), 0.7), (l1('adaptability'), 0.2)]),
    'managementLeadership': wavg([(l1('leadershipInitiative'), 0.5), (l3('leadershipOrientation'), 0.4), (l4('ownership'), 0.2)]),
    'operations': wavg([(l4('executionDiscipline'), 0.4), (l4('reliability'), 0.3), (l4('attentionToDetail'), 0.2)]),
    'entrepreneurial': wavg([(l2('entrepreneurialDrive'), 0.6), (l1('ambitionGrowth'), 0.3), (l4('professionalJudgement'), 0.1)]),
  };
}

CareerDnaLevel5Result computeCareerDnaLevel5Result(Map<String, String> answers, CareerDnaProfile currentProfile) {
  final own = normalizedDimensionScores(
    questions: careerDnaLevel5Questions,
    answers: answers,
    dimensions: careerDnaLevel5Dimensions,
  );
  final crossMapped = _crossTestMappedScores(currentProfile);

  final blended = {
    for (final d in careerDnaLevel5Dimensions) d: ((own[d] ?? 0) * 0.5 + (crossMapped[d] ?? 0) * 0.5).round().clamp(0, 100),
  };

  final ranked = _priorityOrder.toList()..sort((a, b) => (blended[b] ?? 0).compareTo(blended[a] ?? 0));
  final topDirections = ranked.take(5).map((d) => CareerDnaDirectionFit(name: _directions[d]!.label, fitPercent: blended[d] ?? 0)).toList();

  final roleFits = <CareerDnaRoleFit>[];
  for (final d in ranked.take(3)) {
    final fit = blended[d] ?? 0;
    for (var i = 0; i < _directions[d]!.roles.length && roleFits.length < 6 && i < 2; i++) {
      roleFits.add(CareerDnaRoleFit(name: _directions[d]!.roles[i], fitPercent: (fit - i * 3).clamp(0, 100)));
    }
  }

  final topDim = ranked.first;
  final secondDim = ranked[1];
  final spread = ((own[topDim] ?? 0) - (crossMapped[topDim] ?? 0)).abs();
  final gapToSecond = (blended[topDim] ?? 0) - (blended[secondDim] ?? 0);

  // Thresholds are implementation-tunable, not fixed law — a deliberately
  // simplified read of "does this student's own Level 5 answers agree with
  // what Levels 1-4 already showed" rather than decomposing every source
  // test's individual contribution separately.
  String tier;
  String tierText;
  if (spread <= 15 && (own[topDim] ?? 0) >= 65 && (crossMapped[topDim] ?? 0) >= 65) {
    tier = 'high';
    tierText = 'Your results show strong consistency toward ${_directions[topDim]!.label} and related paths.';
  } else if (gapToSecond <= 10 || (spread > 15 && spread <= 30)) {
    tier = 'moderate';
    tierText =
        'Some signals point clearly toward ${_directions[topDim]!.label}, while others suggest a real pull toward ${_directions[secondDim]!.label} too — hybrid roles blending both may suit you particularly well.';
  } else {
    tier = 'exploratory';
    tierText = 'Your profile spans a genuine mix of directions. Further exploration through internships, projects and real exposure is worth it before narrowing down.';
  }

  final pack = _packs[topDim]!;

  return CareerDnaLevel5Result(
    ownDimensionScores: own,
    blendedDimensionScores: blended,
    topDirections: topDirections,
    topRoles: roleFits,
    confidenceTier: tier,
    confidenceText: tierText,
    careerStrengths: pack.strengths,
    developmentAreas: pack.developmentAreas,
    nextSteps: pack.nextSteps,
    completedAt: DateTime.now().toIso8601String(),
  );
}
