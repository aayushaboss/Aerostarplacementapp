import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import '../../utils/career_dna_scoring.dart';

/// Level 2 — Interest & Career Preference. 20 questions, transcribed
/// verbatim from the source assessment doc, across 5 sections (Attraction,
/// Problem Preference, Career Motivators, Work & Career Environment, Career
/// Direction). Unlike Level 1, this level's questions run a clean A/B/C/D
/// axis most of the time (roughly Analytical/People/Creative/Business), but
/// the actual weight matrices below are authored per-option from what each
/// option's own wording actually signals — not a blind position-based rule
/// — since a few options (the "D" choices especially) lean toward
/// Entrepreneurial Drive or Execution & Operations rather than plain
/// Business & Leadership, and a handful of options (Q2b, Q3a, Q5d, Q17a,
/// Q18a) signal Technology specifically. Options are trimmed to fit one
/// line wherever reasonably possible, matching Level 1's own treatment.
const List<String> careerDnaLevel2Dimensions = [
  'analytical',
  'peopleSocial',
  'creative',
  'businessLeadership',
  'technology',
  'executionOperations',
  'learningExpertise',
  'entrepreneurialDrive',
];

final List<CareerDnaQuestion> careerDnaLevel2Questions = [
  const CareerDnaQuestion(
    id: 'l2q1',
    text: 'You suddenly get a completely free Saturday. Which activity would you most enjoy?',
    options: [
      CareerDnaOption(id: 'a', text: 'Learning how something works.', weights: {'learningExpertise': 4, 'analytical': 2}),
      CareerDnaOption(id: 'b', text: 'Meeting friends or attending an event.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'Creating a design, video or project.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Planning something useful and doing it.', weights: {'executionOperations': 4}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q2',
    text: 'Your college announces a competition with four categories. Which are you most interested in?',
    options: [
      CareerDnaOption(id: 'a', text: 'Business case or strategy competition.', weights: {'businessLeadership': 4}),
      CareerDnaOption(id: 'b', text: 'Coding or technology challenge.', weights: {'technology': 4, 'analytical': 2}),
      CareerDnaOption(id: 'c', text: 'Debate or public speaking.', weights: {'peopleSocial': 3, 'businessLeadership': 2}),
      CareerDnaOption(id: 'd', text: 'Design or creative competition.', weights: {'creative': 4}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q3',
    text: 'You see a new app you have never used before. What makes you most curious?',
    options: [
      CareerDnaOption(id: 'a', text: 'Understanding how it works.', weights: {'technology': 3, 'analytical': 3}),
      CareerDnaOption(id: 'b', text: 'Seeing what problems it can solve.', weights: {'businessLeadership': 3, 'analytical': 2}),
      CareerDnaOption(id: 'c', text: 'How attractive or easy to use it is.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'How many people could use it.', weights: {'entrepreneurialDrive': 3, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q4',
    text: 'Which activity could keep you interested for hours with nobody forcing you to do it?',
    options: [
      CareerDnaOption(id: 'a', text: 'Analysing information and finding patterns.', weights: {'analytical': 4}),
      CareerDnaOption(id: 'b', text: 'Talking to and understanding people.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'Creating or experimenting with ideas.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Organising people toward a result.', weights: {'executionOperations': 4, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q5',
    text: "Your college canteen has a long wait. You're asked to help. Which part interests you most?",
    options: [
      CareerDnaOption(id: 'a', text: 'Studying the numbers behind the delay.', weights: {'analytical': 4}),
      CareerDnaOption(id: 'b', text: 'Talking to students about complaints.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'Designing a better ordering experience.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Building a system to speed it up.', weights: {'technology': 3, 'executionOperations': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q6',
    text: 'A friend starts a small online business and asks for help. Which task interests you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Understanding customers, convincing them to buy.', weights: {'peopleSocial': 3, 'businessLeadership': 2}),
      CareerDnaOption(id: 'b', text: 'Managing expenses, pricing, profitability.', weights: {'analytical': 3, 'businessLeadership': 2}),
      CareerDnaOption(id: 'c', text: 'Creating social content and branding.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Planning how the business can grow.', weights: {'businessLeadership': 3, 'entrepreneurialDrive': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q7',
    text: 'Given a completely unfamiliar problem, what is your natural first instinct?',
    options: [
      CareerDnaOption(id: 'a', text: 'Research and understand it deeply.', weights: {'analytical': 3, 'learningExpertise': 3}),
      CareerDnaOption(id: 'b', text: 'Discuss it and collect other opinions.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'Think of unusual, creative possibilities.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Start trying solutions and see what works.', weights: {'executionOperations': 3, 'entrepreneurialDrive': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q8',
    text: 'Which statement sounds most like you?',
    options: [
      CareerDnaOption(id: 'a', text: 'I enjoy figuring out why something happens.', weights: {'analytical': 4}),
      CareerDnaOption(id: 'b', text: 'I enjoy figuring out what people need.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'I enjoy thinking about what could be made.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'I enjoy figuring out how to make it happen.', weights: {'executionOperations': 3, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q9',
    text: 'Two job offers, same salary. Which would attract you more?',
    options: [
      CareerDnaOption(id: 'a', text: 'A job where I keep learning new things.', weights: {'learningExpertise': 4}),
      CareerDnaOption(id: 'b', text: 'A job with many different people.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'A job with freedom to create.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'A job with clear targets and fast growth.', weights: {'businessLeadership': 3, 'entrepreneurialDrive': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q10',
    text: 'Which achievement would satisfy you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Solving a problem nobody could figure out.', weights: {'analytical': 4}),
      CareerDnaOption(id: 'b', text: 'Influencing a large number of people.', weights: {'peopleSocial': 3, 'businessLeadership': 2}),
      CareerDnaOption(id: 'c', text: 'Creating something people appreciate.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Building something successful from scratch.', weights: {'entrepreneurialDrive': 4, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q11',
    text: 'What would frustrate you most in a career?',
    options: [
      CareerDnaOption(id: 'a', text: 'Repeating the same thing without learning.', weights: {'learningExpertise': 3}),
      CareerDnaOption(id: 'b', text: 'Working alone with little interaction.', weights: {'peopleSocial': 3}),
      CareerDnaOption(id: 'c', text: 'No freedom to bring my own ideas.', weights: {'creative': 3}),
      CareerDnaOption(id: 'd', text: 'No clear goals or measurable results.', weights: {'executionOperations': 3, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q12',
    text: 'If you become highly successful, which would matter most to you?',
    options: [
      CareerDnaOption(id: 'a', text: 'Becoming highly knowledgeable or skilled.', weights: {'learningExpertise': 4}),
      CareerDnaOption(id: 'b', text: 'Becoming influential, respected by people.', weights: {'peopleSocial': 3, 'businessLeadership': 2}),
      CareerDnaOption(id: 'c', text: 'Becoming known for originality.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Having authority and real decisions.', weights: {'businessLeadership': 4}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q13',
    text: 'Which working environment sounds most attractive?',
    options: [
      CareerDnaOption(id: 'a', text: 'Deep focus on challenging problems.', weights: {'analytical': 4}),
      CareerDnaOption(id: 'b', text: 'Highly social, full of meetings, people.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'Creative, experimentation encouraged.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Fast-moving, decisions and results matter.', weights: {'businessLeadership': 3, 'executionOperations': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q14',
    text: 'Given a project with no detailed instructions, what would you prefer?',
    options: [
      CareerDnaOption(id: 'a', text: 'Freedom to research the best approach.', weights: {'analytical': 3, 'learningExpertise': 2}),
      CareerDnaOption(id: 'b', text: 'Freedom to build it together with others.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'Freedom to experiment and create.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Freedom to own it and deliver the result.', weights: {'executionOperations': 3, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q15',
    text: 'Which type of recognition would motivate you most?',
    options: [
      CareerDnaOption(id: 'a', text: '"You are extremely knowledgeable."', weights: {'learningExpertise': 4}),
      CareerDnaOption(id: 'b', text: '"You are excellent with people."', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: '"You are highly creative."', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: '"You get things done."', weights: {'executionOperations': 4}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q16',
    text: 'If you had to spend a whole day on only ONE activity, which would you choose?',
    options: [
      CareerDnaOption(id: 'a', text: 'Analyse data or complex situations.', weights: {'analytical': 4}),
      CareerDnaOption(id: 'b', text: 'Meet and interact with different people.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'Design, write or develop ideas.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Plan, manage or execute activities.', weights: {'executionOperations': 3, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q17',
    text: 'Which of these career areas would you be most curious to explore?',
    options: [
      CareerDnaOption(id: 'a', text: 'Technology, Data, Analytics or Research.', weights: {'technology': 3, 'analytical': 3}),
      CareerDnaOption(id: 'b', text: 'Sales, Marketing, HR or Consulting.', weights: {'peopleSocial': 3, 'businessLeadership': 2}),
      CareerDnaOption(id: 'c', text: 'Design, Media, Content or Advertising.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Business, Management or Entrepreneurship.', weights: {'businessLeadership': 3, 'entrepreneurialDrive': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q18',
    text: 'You get ₹10 lakh to start a project. Which idea excites you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Build a technology-based product.', weights: {'technology': 4}),
      CareerDnaOption(id: 'b', text: 'Build a service solving a real problem.', weights: {'peopleSocial': 2, 'businessLeadership': 3}),
      CareerDnaOption(id: 'c', text: 'Build a creative brand or media platform.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'Build a scalable business, grow it fast.', weights: {'entrepreneurialDrive': 4, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q19',
    text: 'Which type of problem would you willingly spend hours on?',
    options: [
      CareerDnaOption(id: 'a', text: '"Why is this happening, per the data?"', weights: {'analytical': 4}),
      CareerDnaOption(id: 'b', text: '"Why are people behaving this way?"', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: '"How can we create something different?"', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: '"How do we turn this into a result?"', weights: {'entrepreneurialDrive': 3, 'businessLeadership': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l2q20',
    text: 'Forget salary and expectations. Which feels closest to the career you want to build?',
    options: [
      CareerDnaOption(id: 'a', text: 'I want to become an expert.', weights: {'learningExpertise': 4, 'analytical': 2}),
      CareerDnaOption(id: 'b', text: 'I want to work with people.', weights: {'peopleSocial': 4}),
      CareerDnaOption(id: 'c', text: 'I want to create.', weights: {'creative': 4}),
      CareerDnaOption(id: 'd', text: 'I want to lead and build.', weights: {'businessLeadership': 4, 'entrepreneurialDrive': 2}),
    ],
  ),
];

class _InterestHeadline {
  final String title;
  final String firstSentence;
  final String phrase; // used inline in the narrative summary
  final List<String> explorationChain;
  const _InterestHeadline({required this.title, required this.firstSentence, required this.phrase, required this.explorationChain});
}

const _headlines = {
  'analytical': _InterestHeadline(
    title: 'The Analytical Mind',
    firstSentence: "You're naturally drawn to information, patterns, and understanding why things work the way they do.",
    phrase: 'digging into data and figuring out why something happens',
    explorationChain: ['Data Analyst', 'Business Analyst', 'Product Analytics', 'Technology Consulting', 'Research'],
  ),
  'technology': _InterestHeadline(
    title: 'The Tech Explorer',
    firstSentence: "You're naturally drawn to how things are built, and to the systems and tools that make them work.",
    phrase: 'understanding how systems and technology work',
    explorationChain: ['Software Developer', 'Product Engineer', 'Technology Consulting', 'Product Management', 'Technical Architecture'],
  ),
  'peopleSocial': _InterestHeadline(
    title: 'The People Connector',
    firstSentence: "You're naturally drawn to people — understanding them, talking to them, and building real connections.",
    phrase: 'understanding and connecting with people',
    explorationChain: ['Sales', 'Business Development', 'Marketing', 'Consulting', 'Entrepreneurship'],
  ),
  'businessLeadership': _InterestHeadline(
    title: 'The Business Builder',
    firstSentence: "You're naturally drawn to ownership, decisions, and turning opportunities into real outcomes.",
    phrase: 'taking ownership and making decisions',
    explorationChain: ['Management Trainee', 'Business Development', 'Operations Manager', 'General Management', 'Entrepreneurship'],
  ),
  'creative': _InterestHeadline(
    title: 'The Creative Thinker',
    firstSentence: "You're naturally drawn to ideas, originality, and building things that haven't quite been built before.",
    phrase: 'coming up with original ideas',
    explorationChain: ['Content Creator', 'Brand Designer', 'Creative Strategist', 'Media Production', 'Creative Direction'],
  ),
  'executionOperations': _InterestHeadline(
    title: 'The Execution Specialist',
    firstSentence: "You're naturally drawn to getting things done — planning, organising, and making sure things actually happen.",
    phrase: 'planning and getting things actually done',
    explorationChain: ['Operations Associate', 'Project Coordinator', 'Operations Manager', 'Program Management', 'Business Operations Lead'],
  ),
  'learningExpertise': _InterestHeadline(
    title: 'The Knowledge Seeker',
    firstSentence: "You're naturally drawn to mastering a subject deeply, rather than knowing a little about everything.",
    phrase: 'mastering a subject in real depth',
    explorationChain: ['Research Associate', 'Subject-Matter Specialist', 'Domain Consultant', 'Industry Researcher', 'Expert Advisor'],
  ),
  'entrepreneurialDrive': _InterestHeadline(
    title: 'The Opportunity Seeker',
    firstSentence: "You're naturally drawn to opportunity, risk, and building something from the ground up.",
    phrase: 'spotting and chasing new opportunities',
    explorationChain: ['Startup Associate', 'Business Development', "Founder's Office", 'Venture Building', 'Entrepreneurship'],
  ),
};

// Fixed tie-break priority — highest raw score wins; ties resolved in this order.
const _priorityOrder = ['analytical', 'technology', 'peopleSocial', 'businessLeadership', 'creative', 'executionOperations', 'learningExpertise', 'entrepreneurialDrive'];

CareerDnaLevel2Result computeCareerDnaLevel2Result(Map<String, String> answers) {
  final scores = normalizedDimensionScores(
    questions: careerDnaLevel2Questions,
    answers: answers,
    dimensions: careerDnaLevel2Dimensions,
  );

  var topDim = _priorityOrder.first;
  var topScore = -1;
  for (final d in _priorityOrder) {
    final s = scores[d] ?? 0;
    if (s > topScore) {
      topScore = s;
      topDim = d;
    }
  }
  final headline = _headlines[topDim]!;

  return CareerDnaLevel2Result(
    dimensionScores: scores,
    careerExplorationChain: headline.explorationChain,
    headlineText: headline.title,
    completedAt: DateTime.now().toIso8601String(),
  );
}

/// Phrase per dimension, for the narrative snapshot on the report screen —
/// mirrors career_dna_level1_data.dart's naming convention.
const careerDnaLevel2DimensionPhrases = {
  'analytical': 'digging into data and figuring out why something happens',
  'peopleSocial': 'understanding and connecting with people',
  'creative': 'coming up with original ideas',
  'businessLeadership': 'taking ownership and making decisions',
  'technology': 'understanding how systems and technology work',
  'executionOperations': 'planning and getting things actually done',
  'learningExpertise': 'mastering a subject in real depth',
  'entrepreneurialDrive': 'spotting and chasing new opportunities',
};

/// The hero's opening sentence for a completed Level 2 result — keyed off
/// the same headline used to name the result.
String careerDnaLevel2HeroSentence(String headlineText) {
  final entry = _headlines.values.firstWhere((h) => h.title == headlineText, orElse: () => _headlines['analytical']!);
  return entry.firstSentence;
}
