import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/parsed_resume.dart';
import 'chat_models.dart';
import 'resume_chat_engine.dart';

/// Resume Helper backed by Claude, through `server/resume_helper_server.js`.
/// The server owns the API key and the system prompt; this class only keeps the
/// conversation, sends it, and turns the structured reply into a [ChatTurn].
class LlmResumeEngine implements ResumeChatEngine {
  LlmResumeEngine(this.ctx, {required this.endpoint, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'content-type': 'application/json'},
            ));

  final ResumeChatContext ctx;
  final String endpoint;
  final Dio _dio;

  /// {role, content} pairs the server turns into the Claude conversation.
  final List<Map<String, String>> _history = [];
  ParsedResume? _draft;
  String? _notice;

  @override
  String? get notice => _notice;

  @override
  bool get hasContent {
    final d = _draft;
    return d != null && (d.education.isNotEmpty || d.skills.isNotEmpty || d.workExperience.isNotEmpty || d.projects.isNotEmpty);
  }

  @override
  ParsedResume? draftSnapshot() {
    final d = _draft;
    if (d == null || !hasContent) return null;
    return ParsedResume(
      name: d.name,
      headline: d.headline,
      phone: d.phone,
      education: d.education,
      skills: d.skills,
      projects: d.projects,
      links: d.links,
      experienceLevel: d.experienceLevel,
      summary: d.summary,
      workExperience: d.workExperience,
      certifications: d.certifications,
      achievements: d.achievements,
      isDraft: true,
    );
  }

  @override
  Future<ChatTurn> start() => _chat([
        // The conversation must open with a user turn; keeping it in the history
        // means every later request still contains Claude's own first question.
        {'role': 'user', 'content': '(The student just opened the Resume Helper. Start the chat.)'},
      ]);

  @override
  Future<ChatTurn> answer(UserAnswer answer, {String? shown}) {
    final text = switch (answer.kind) {
      AnswerKind.skip => '(The student skipped this question.)',
      AnswerKind.multi => answer.items.join(', '),
      _ => (shown ?? answer.text).trim(),
    };
    return _chat([
      {'role': 'user', 'content': text.isEmpty ? '(no text)' : text},
    ]);
  }

  Future<ChatTurn> _chat(List<Map<String, String>> newMessages) async {
    final json = await _post({'action': 'chat', 'messages': [..._history, ...newMessages], 'context': _contextJson()});
    final turn = _turnFromJson(json);
    _history
      ..addAll(newMessages)
      ..add({'role': 'assistant', 'content': jsonEncode(_replyForHistory(json))});
    _draft = _resumeFromJson((json['draft_resume'] as Map?)?.cast<String, dynamic>() ?? const {}, draft: true);
    _notice = null;
    return turn;
  }

  @override
  Future<ResumeBuildResult> build({bool draft = false}) async {
    if (draft) {
      final snap = draftSnapshot();
      return ResumeBuildResult(resume: snap ?? _emptyResume(draft: true), pleaseCheck: const []);
    }
    try {
      final json = await _post({'action': 'build', 'messages': _history, 'context': _contextJson()});
      final resume = _resumeFromJson((json['resume'] as Map?)?.cast<String, dynamic>() ?? const {}, draft: false);
      final checks = ((json['please_check'] as List?) ?? const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();
      return ResumeBuildResult(resume: resume, pleaseCheck: checks);
    } on ResumeBotUnavailable {
      // The polish step failed, but nothing the student said is lost: use the
      // facts collected so far, un-polished, and say so.
      final base = draftSnapshot() ?? _emptyResume(draft: true);
      return ResumeBuildResult(
        resume: ParsedResume(
          name: base.name,
          headline: base.headline,
          phone: base.phone,
          education: base.education,
          skills: base.skills,
          projects: base.projects,
          links: base.links,
          experienceLevel: base.experienceLevel,
          summary: base.summary,
          workExperience: base.workExperience,
          certifications: base.certifications,
          achievements: base.achievements,
        ),
        pleaseCheck: ["I couldn't polish the wording this time, so this is exactly what you told me. Please read it through."],
      );
    }
  }

  // ------------------------------------------------------------ network

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    Object? last;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _dio.post<dynamic>(endpoint, data: jsonEncode(body));
        final data = res.data;
        final map = data is String ? jsonDecode(data) : data;
        if (map is Map) return map.cast<String, dynamic>();
        last = 'unexpected reply';
      } on DioException catch (e) {
        last = e.response?.statusCode ?? e.type.name;
        final code = e.response?.statusCode;
        // No key / no such endpoint: retrying will not help.
        if (code == 503 || code == 404 || code == 405) break;
      } catch (e) {
        last = e;
      }
    }
    debugPrint('LlmResumeEngine: request failed - $last');
    throw ResumeBotUnavailable('$last');
  }

  // ------------------------------------------------------------ mapping

  Map<String, dynamic> _contextJson() => {
        'name': ctx.name,
        'phone': ctx.phone,
        'email': ctx.email,
        'college': ctx.college,
        'course': ctx.course,
        'semester': ctx.semester,
        if (ctx.existing != null) 'existing_resume': _existingJson(ctx.existing!),
        'existing_is_draft': ctx.existingIsDraft,
        'earned_certificates': ctx.earnedCertificates.map((c) => {'name': c.name, 'duration': c.duration}).toList(),
      };

  Map<String, dynamic> _existingJson(ParsedResume r) => {
        'headline': r.headline,
        'phone': r.phone,
        'summary': r.summary,
        'experience_level': r.experienceLevel,
        'education': r.education.map((e) => {'degree': e.degree, 'institution': e.institution, 'duration': e.duration, 'gpa': e.gpa}).toList(),
        'skills': r.skills,
        'experience': r.workExperience.map((w) => {'company': w.company, 'role': w.role, 'duration': w.duration, 'bullets': w.description.split('\n').where((l) => l.trim().isNotEmpty).toList()}).toList(),
        'projects': r.projects.map((p) => {'title': p.title, 'description': p.description}).toList(),
        'certifications': r.certifications.map((c) => {'name': c.name, 'duration': c.duration}).toList(),
        'achievements': r.achievements,
      };

  Map<String, dynamic> _replyForHistory(Map<String, dynamic> j) => {
        'message': j['message'],
        'topic': j['topic'],
        'answer_type': j['answer_type'],
        'choices': j['choices'],
        'skippable': j['skippable'],
        'questions_done': j['questions_done'],
        'questions_total': j['questions_total'],
        'ready_to_build': j['ready_to_build'],
        'draft_resume': j['draft_resume'],
      };

  ChatTurn _turnFromJson(Map<String, dynamic> j) {
    final topic = ChatTopic.values.firstWhere((t) => t.name == j['topic'], orElse: () => ChatTopic.other);
    final type = switch (j['answer_type']) {
      'choices' => AnswerType.choices,
      'multi' => AnswerType.multi,
      'confirm' => AnswerType.confirm,
      'none' => AnswerType.none,
      _ => AnswerType.text,
    };
    final choices = ((j['choices'] as List?) ?? const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();
    final done = (j['questions_done'] as num?)?.toInt() ?? 0;
    final total = (j['questions_total'] as num?)?.toInt() ?? done + 1;
    // A button question with no buttons would strand the student: let them type.
    final effective = (type == AnswerType.choices || type == AnswerType.multi) && choices.isEmpty ? AnswerType.text : type;
    return ChatTurn(
      message: (j['message'] as String?)?.trim().isNotEmpty == true ? j['message'] as String : 'Tell me a bit more?',
      topic: topic,
      answerType: effective,
      choices: choices,
      skippable: j['skippable'] == true,
      questionsDone: done,
      questionsTotal: total < done ? done : total,
      readyToBuild: j['ready_to_build'] == true,
      offerForm: j['offer_form'] == true,
    );
  }

  ParsedResume _emptyResume({required bool draft}) => ParsedResume(
        name: ctx.name,
        phone: ctx.phone,
        education: const [],
        skills: const [],
        projects: const [],
        links: ctx.existing?.links ?? const [],
        isDraft: draft,
      );

  ParsedResume _resumeFromJson(Map<String, dynamic> r, {required bool draft}) {
    List<Map<String, dynamic>> list(String key) => ((r[key] as List?) ?? const []).whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
    String s(Object? v) => (v is String) ? v.trim() : '';
    String? orNull(Object? v) => s(v).isEmpty ? null : s(v);
    final level = s(r['experience_level']);
    final ex = ctx.existing;
    return ParsedResume(
      name: ctx.name,
      headline: orNull(r['headline']) ?? ex?.headline,
      phone: orNull(r['phone']) ?? (ctx.phone?.trim().isEmpty ?? true ? null : ctx.phone),
      education: list('education')
          .map((e) => ResumeEducation(degree: s(e['degree']), institution: s(e['institution']), duration: s(e['duration']), gpa: orNull(e['gpa'])))
          .toList(),
      skills: ((r['skills'] as List?) ?? const []).map(s).where((e) => e.isNotEmpty).toList(),
      projects: list('projects').map((p) => ResumeProject(title: s(p['title']), description: s(p['description']))).toList(),
      links: ex?.links ?? const [],
      experienceLevel: level.isNotEmpty ? level : ex?.experienceLevel,
      specializations: ex?.specializations ?? const [],
      summary: orNull(r['summary']),
      workExperience: list('experience')
          .map((w) => WorkExperience(
                company: s(w['company']),
                role: s(w['role']),
                duration: s(w['duration']),
                description: ((w['bullets'] as List?) ?? const []).map(s).where((e) => e.isNotEmpty).join('\n'),
              ))
          .toList(),
      certifications: [
        ...list('certifications').map((c) => ResumeCertification(name: s(c['name']), duration: s(c['duration']))),
        ...ctx.earnedCertificates.where((e) => !list('certifications').any((c) => s(c['name']).toLowerCase() == e.name.toLowerCase())),
      ],
      portfolioLink: ex?.portfolioLink,
      portfolioFileName: ex?.portfolioFileName,
      achievements: ((r['achievements'] as List?) ?? const []).map(s).where((e) => e.isNotEmpty).toList(),
      isDraft: draft,
    );
  }
}
