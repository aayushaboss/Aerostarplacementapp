import 'dart:async';

import '../../models/parsed_resume.dart';
import 'chat_models.dart';

/// The brain of the Resume Helper. The chat screen only talks to this
/// interface, so the scripted rule engine and the Claude-backed engine are
/// interchangeable. Methods return [FutureOr]: the scripted engine answers
/// instantly, the Claude engine over the network.
abstract class ResumeChatEngine {
  /// The opening turn.
  FutureOr<ChatTurn> start();

  /// Feeds the student's answer, returns the next turn. [shown] is the exact
  /// text the student saw themselves send (button label, typed text).
  FutureOr<ChatTurn> answer(UserAnswer answer, {String? shown});

  /// A short line the app shows as the bot's own message before the next turn
  /// when the last answer was off-topic or unclear (null otherwise).
  String? get notice;

  /// Compiles everything collected so far. [draft] marks the resume as an
  /// unfinished autosave.
  FutureOr<ResumeBuildResult> build({bool draft = false});

  /// A cheap, synchronous snapshot for autosaving a half-finished chat (null
  /// when nothing worth saving has been collected yet).
  ParsedResume? draftSnapshot();

  /// True when something has been collected that is worth autosaving.
  bool get hasContent;
}

/// Thrown by a network-backed engine when it cannot get a reply.
class ResumeBotUnavailable implements Exception {
  final String reason;
  const ResumeBotUnavailable(this.reason);

  @override
  String toString() => 'ResumeBotUnavailable: $reason';
}
