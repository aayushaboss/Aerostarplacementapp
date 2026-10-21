import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import 'career_dna_level1_data.dart';
import 'career_dna_level2_data.dart';
import 'career_dna_level3_data.dart';
import 'career_dna_level4_data.dart';
import 'career_dna_level5_data.dart';

/// Single dispatch point so the shared quiz/report screens never need to
/// know which level they're driving — each level's own question bank +
/// scoring lives in its own career_dna_levelN_data.dart file (see
/// career_dna_level1_data.dart for the authoring pattern every level
/// follows). Phase B: all 5 levels now wired.
List<CareerDnaQuestion> careerDnaQuestionsForLevel(int level) {
  switch (level) {
    case 1:
      return careerDnaLevel1Questions;
    case 2:
      return careerDnaLevel2Questions;
    case 3:
      return careerDnaLevel3Questions;
    case 4:
      return careerDnaLevel4Questions;
    case 5:
      return careerDnaLevel5Questions;
    default:
      return const [];
  }
}

/// Runs the right level's scoring + persists the result shape onto a
/// [CareerDnaProfile] copy. [current] is the student's profile so far —
/// needed by Level 5, whose own scoring cross-references Levels 1-4's
/// already-computed results (see career_dna_level5_data.dart).
CareerDnaProfile computeAndApplyCareerDnaLevel(int level, Map<String, String> answers, CareerDnaProfile current) {
  switch (level) {
    case 1:
      return current.copyWith(level1: computeCareerDnaLevel1Result(answers));
    case 2:
      return current.copyWith(level2: computeCareerDnaLevel2Result(answers));
    case 3:
      return current.copyWith(level3: computeCareerDnaLevel3Result(answers));
    case 4:
      return current.copyWith(level4: computeCareerDnaLevel4Result(answers));
    case 5:
      return current.copyWith(level5: computeCareerDnaLevel5Result(answers, current));
    default:
      return current;
  }
}
