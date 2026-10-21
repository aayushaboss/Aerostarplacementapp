import 'package:flutter/foundation.dart';

/// Where the Resume Helper's Claude-backed server lives.
///
/// - `--dart-define=RESUME_BOT=scripted` forces the built-in rule-based helper.
/// - `--dart-define=RESUME_BOT_URL=https://.../api/resume-chat` points at a
///   deployed server.
/// - By default on web it uses the same origin the app was served from
///   (`/api/resume-chat`), which is what `server/resume_helper_server.js`
///   provides. If that endpoint is missing or has no API key (for example on
///   GitHub Pages), the chat falls back to the built-in helper automatically.
class ResumeBotConfig {
  ResumeBotConfig._();

  static const _mode = String.fromEnvironment('RESUME_BOT', defaultValue: 'llm');
  static const _url = String.fromEnvironment('RESUME_BOT_URL');

  static String? get endpoint {
    if (_mode == 'scripted') return null;
    if (_url.isNotEmpty) return _url;
    if (kIsWeb) return '${Uri.base.origin}/api/resume-chat';
    return null;
  }
}
