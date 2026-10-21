import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/widgets.dart' show IconData;

/// Display-only metadata for all 5 Career DNA levels — used by the landing
/// (level-map) screen and each level's own intro screen. Kept separate from
/// each level's real question-bank/scoring file (career_dna_levelN_data.dart)
/// so the landing screen can render all 5 level cards (including the locked
/// ones, whose content may not be authored yet) without importing every
/// level's full weight-matrix data.
class CareerDnaLevelMeta {
  final int level;
  final String title;
  final String tagline;
  final String whatThisMeasures;
  final String noRightWrongCopy;
  final IconData icon;
  final int questionCount;
  final String estTime;

  const CareerDnaLevelMeta({
    required this.level,
    required this.title,
    required this.tagline,
    required this.whatThisMeasures,
    required this.noRightWrongCopy,
    required this.icon,
    required this.questionCount,
    required this.estTime,
  });
}

// `title` is each level's formal, named test methodology (shown on the
// landing map, the intro screen, and PDF headers) — a credibility play,
// tying the product to real, recognizable psychometric frameworks rather
// than a generic in-house description. `whatThisMeasures` is a short,
// genuinely brief (2 sentences, ~3-4 rendered lines — a first draft ran
// much longer and read as a wall of text on the intro screen) explanation
// of what that named test actually is and how it helps — honest,
// non-clinical framing appropriate for a student product, never
// overclaiming validity. It's reused verbatim in two
// places: the intro screen's own paragraph, and the landing screen's
// per-node tap-to-reveal tooltip (career_dna_landing_screen.dart) — one
// string, no content to keep in sync across two authored copies.
// `tagline`/`noRightWrongCopy` stay short fragments as before; only
// `title`/`whatThisMeasures` carry the fuller copy now. Also scrubbed of
// college-only framing ("college situations", "your first job" assuming a
// first job specifically) since this feature spans every non-school
// segment (UG/PG/Working), not just current students.
const careerDnaLevelMeta = [
  CareerDnaLevelMeta(
    level: 1,
    title: 'Big Five (OCEAN)',
    tagline: 'How do you naturally act?',
    whatThisMeasures:
        "One of psychology's most well-researched personality frameworks. It shows how you think, work, and relate to others — so you can pick a "
        "path that genuinely fits you.",
    noRightWrongCopy: 'No right or wrong answers — just be yourself.',
    icon: Ionicons.person_outline,
    questionCount: 20,
    estTime: '8–10 min',
  ),
  CareerDnaLevelMeta(
    level: 2,
    title: 'Situational Judgement Test',
    tagline: 'What attracts you?',
    whatThisMeasures:
        "Puts you in realistic workplace scenarios to see how you'd actually respond — not what you know, but how you'd act under pressure.",
    noRightWrongCopy: 'Pick what feels like you, not what sounds impressive.',
    icon: Ionicons.compass_outline,
    questionCount: 20,
    estTime: '12–15 min',
  ),
  CareerDnaLevelMeta(
    level: 3,
    title: 'Hogan Personality Inventory Test',
    tagline: 'How do you interact with people?',
    whatThisMeasures:
        "A well-known read on your everyday working style — not clinical, just how you naturally show up, build relationships, and handle pressure "
        "in a team.",
    noRightWrongCopy: "Answer with what you'd really do, not the 'right' answer.",
    icon: Ionicons.people_outline,
    questionCount: 20,
    estTime: '15–18 min',
  ),
  CareerDnaLevelMeta(
    level: 4,
    title: 'DISC Assessment',
    tagline: 'How do you operate at work?',
    whatThisMeasures:
        "One of the most widely used workplace-behaviour frameworks. It shows how you naturally decide, communicate, and handle change at work.",
    noRightWrongCopy: "Answer honestly — not what your manager wants to hear.",
    icon: Ionicons.briefcase_outline,
    questionCount: 20,
    estTime: '18–20 min',
  ),
  CareerDnaLevelMeta(
    level: 5,
    title: 'Holland RIASEC Career Test',
    tagline: 'Where do all four dimensions point you?',
    whatThisMeasures:
        "One of the most widely used career-matching frameworks. It combines everything from Levels 1–4 to map out real career directions worth "
        "exploring.",
    noRightWrongCopy: "Pick what you'd genuinely enjoy, not the highest-paying option.",
    icon: Ionicons.rocket_outline,
    questionCount: 20,
    estTime: '20–25 min',
  ),
];
