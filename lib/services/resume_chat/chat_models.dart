import '../../models/parsed_resume.dart';

/// What a chat reply is about — mirrors the "what you are asking about"
/// line of the Resume Helper's reply format.
enum ChatTopic { confirm, contact, education, skills, experience, projects, other, done }

/// How the student should answer — the "how they should answer" line.
enum AnswerType {
  /// Free typing.
  text,

  /// Pick exactly one button.
  choices,

  /// Pick any number of buttons (and/or type their own).
  multi,

  /// Yes / No style confirmation.
  confirm,

  /// Nothing to answer (the final "ready to build" turn).
  none,
}

/// One bot reply, in the structured shape the app renders:
/// message, topic, answer type, buttons, skippable, progress, ready flag.
class ChatTurn {
  final String message;
  final ChatTopic topic;
  final AnswerType answerType;
  final List<String> choices;
  final bool skippable;

  /// Questions the student has already answered.
  final int questionsDone;

  /// Total questions planned (done + this one + those still to come).
  final int questionsTotal;

  /// All must-haves (contact, education, skills) are in: the app may offer
  /// "Build my resume now" at any point from here on.
  final bool readyToBuild;

  /// The bot is stuck — the app should prominently offer the normal form.
  final bool offerForm;

  const ChatTurn({
    required this.message,
    required this.topic,
    required this.answerType,
    this.choices = const [],
    this.skippable = false,
    required this.questionsDone,
    required this.questionsTotal,
    this.readyToBuild = false,
    this.offerForm = false,
  });
}

/// What the app already knows before the chat starts.
class ResumeChatContext {
  final String name;
  final String? phone;
  final String? email;
  final String? college;
  final String? course;
  final String? semester;

  /// A resume that already exists: freshly uploaded and parsed, or a
  /// half-finished draft being resumed, or a finished one being redone.
  final ParsedResume? existing;

  /// [existing] is an unfinished chat/quiz draft ("welcome back").
  final bool existingIsDraft;

  /// Certificates earned in Aerostar Edge courses — added to the resume
  /// automatically, never asked about. Empty today: the app does not track
  /// course completions yet.
  final List<ResumeCertification> earnedCertificates;

  const ResumeChatContext({
    required this.name,
    this.phone,
    this.email,
    this.college,
    this.course,
    this.semester,
    this.existing,
    this.existingIsDraft = false,
    this.earnedCertificates = const [],
  });
}

enum AnswerKind { text, choice, multi, skip, yes, no }

/// What the student did in response to a [ChatTurn].
class UserAnswer {
  final AnswerKind kind;
  final String text;
  final List<String> items;

  const UserAnswer._(this.kind, this.text, this.items);

  const UserAnswer.text(String text) : this._(AnswerKind.text, text, const []);
  const UserAnswer.choice(String choice) : this._(AnswerKind.choice, choice, const []);
  const UserAnswer.multi(List<String> items) : this._(AnswerKind.multi, '', items);
  const UserAnswer.skip() : this._(AnswerKind.skip, '', const []);
  const UserAnswer.yes() : this._(AnswerKind.yes, '', const []);
  const UserAnswer.no() : this._(AnswerKind.no, '', const []);
}

/// The finished resume plus the "please check" list.
class ResumeBuildResult {
  final ParsedResume resume;

  /// Everything the bot had to guess, tidy up, or could not verify. The
  /// student reviews these before saving.
  final List<String> pleaseCheck;

  const ResumeBuildResult({required this.resume, required this.pleaseCheck});
}
