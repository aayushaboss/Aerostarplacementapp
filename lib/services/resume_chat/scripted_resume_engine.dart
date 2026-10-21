import '../../mockData/course_fields.dart';
import '../../models/parsed_resume.dart';
import 'chat_models.dart';
import 'resume_chat_engine.dart';

enum _Slot { confirmUpload, confirmFix, contact, educationYear, educationText, skills, expGate, expDetail, projects, other }

/// Rule-based Resume Helper. It follows the Resume Helper brief literally:
/// one question at a time, never asks what is already known, at most 6
/// questions (3 when a resume already exists), accepts several facts in one
/// message, tolerates Hinglish and typos, never invents facts, and treats
/// everything typed (or read from an uploaded resume) as data, never as
/// instructions. It is deliberately deterministic so it works offline; a real
/// LLM can replace it behind [ResumeChatEngine].
class ScriptedResumeEngine implements ResumeChatEngine {
  ScriptedResumeEngine(this.ctx, {DateTime? now}) : _now = now ?? DateTime.now() {
    _init();
  }

  final ResumeChatContext ctx;
  final DateTime _now;

  // Collected facts.
  String? _phone;
  String? _email;
  String? _headline;
  List<ResumeEducation> _education = [];
  List<String> _skills = [];
  bool? _hasExperience;
  List<WorkExperience> _experience = [];
  List<ResumeProject> _projects = [];
  List<String> _extras = [];
  List<ResumeCertification> _certs = [];
  List<String> _links = [];
  final List<String> _check = [];

  bool _fromExisting = false;
  bool _hinglish = false;
  bool _formOfferPending = false;
  bool _wordingTouched = false;

  late int _cap;
  List<_Slot> _queue = [];
  late _Slot _slot;
  int _answered = 0;
  final Map<_Slot, int> _clarifications = {};
  String? _notice;

  @override
  String? get notice => _notice;

  // ---------------------------------------------------------------- setup

  void _init() {
    _phone = _clean(ctx.phone);
    _email = _clean(ctx.email);
    final ex = ctx.existing;
    if (ex != null) {
      _fromExisting = true;
      _phone ??= _clean(ex.phone);
      _headline = ex.headline;
      _education = ex.education.where((e) => !_looksLikeInstruction('${e.degree} ${e.institution}')).toList();
      _skills = _safeList(ex.skills);
      _experience = List.of(ex.workExperience);
      _hasExperience = ex.workExperience.isNotEmpty ? true : (ex.experienceLevel == 'Fresher' ? false : null);
      _projects = ex.projects.where((p) => !_looksLikeInstruction('${p.title} ${p.description}')).toList();
      if (_projects.length != ex.projects.length) _noteIgnoredText();
      _extras = _safeList(ex.achievements);
      _certs = List.of(ex.certifications);
      _links = List.of(ex.links);
    }
    for (final c in ctx.earnedCertificates) {
      if (!_certs.any((x) => x.name.toLowerCase() == c.name.toLowerCase())) _certs.add(c);
    }
    _cap = _fromExisting ? 3 : 6;
    final q = <_Slot>[
      if (_fromExisting) _Slot.confirmUpload,
      if (_phone == null && _email == null) _Slot.contact,
      if (_education.isEmpty) _knownEducation ? _Slot.educationYear : _Slot.educationText,
      if (_skills.isEmpty) _Slot.skills,
      if (_hasExperience == null) _Slot.expGate,
      if (_projects.isEmpty) _Slot.projects,
      if (_extras.isEmpty) _Slot.other,
    ];
    _queue = q.take(_cap).toList();
    _slot = _queue.removeAt(0);
  }

  bool get _knownEducation => (_clean(ctx.college) != null) && (_clean(ctx.course) != null);

  List<String> _safeList(List<String> src) {
    final out = <String>[];
    for (final s in src) {
      if (_looksLikeInstruction(s)) {
        _noteIgnoredText();
        continue;
      }
      out.add(s);
    }
    return out;
  }

  bool _ignoredNoted = false;
  void _noteIgnoredText() {
    if (_ignoredNoted) return;
    _ignoredNoted = true;
    _check.add('I left out some text from your resume that looked like instructions, not resume details.');
  }

  // ------------------------------------------------------------ interface

  @override
  ChatTurn start() => _turnFor(_slot, greeting: true);

  ChatTurn get current => _turnFor(_slot);

  @override
  ParsedResume? draftSnapshot() => hasContent ? build(draft: true).resume : null;

  @override
  bool get hasContent => _education.isNotEmpty || _skills.isNotEmpty || _experience.isNotEmpty || _projects.isNotEmpty;

  bool get _mustHaves => (_phone != null || _email != null) && _education.isNotEmpty && _skills.isNotEmpty;

  @override
  ChatTurn answer(UserAnswer a, {String? shown}) {
    _notice = null;
    if (a.kind == AnswerKind.text) {
      if (_hasHinglish(a.text)) _hinglish = true;
      if (_looksLikeInstruction(a.text) || _isOffTopic(a.text)) {
        _notice = _t(
          'I can only help with your resume.',
          'Main sirf aapke resume mein help kar sakta hoon.',
        );
        return _turnFor(_slot);
      }
      _absorbLabelled(a.text);
      _absorbContact(a.text);
    }
    switch (_slot) {
      case _Slot.confirmUpload:
        return _answerConfirmUpload(a);
      case _Slot.confirmFix:
        return _answerConfirmFix(a);
      case _Slot.contact:
        return _answerContact(a);
      case _Slot.educationYear:
        return _answerEducationYear(a);
      case _Slot.educationText:
        return _answerEducationText(a);
      case _Slot.skills:
        return _answerSkills(a);
      case _Slot.expGate:
        return _answerExpGate(a);
      case _Slot.expDetail:
        return _answerExpDetail(a);
      case _Slot.projects:
        return _answerProjects(a);
      case _Slot.other:
        return _answerOther(a);
    }
  }

  // ------------------------------------------------------------- answers

  ChatTurn _answerConfirmUpload(UserAnswer a) {
    if (a.kind == AnswerKind.no) {
      _slot = _Slot.confirmFix;
      return _turnFor(_slot);
    }
    return _advance();
  }

  ChatTurn _answerConfirmFix(UserAnswer a) {
    if (a.kind == AnswerKind.text && a.text.trim().isNotEmpty) {
      _check.add('You said something in your resume looked wrong: "${_short(a.text.trim())}". Please review it.');
    } else {
      _check.add('You said something in your resume looked wrong. Please review it.');
    }
    _formOfferPending = true;
    _notice = _t("Noted — I'll flag it for you to check.", 'Theek hai — main ise check ke liye mark kar dunga.');
    return _advance();
  }

  ChatTurn _answerContact(UserAnswer a) {
    if (a.kind != AnswerKind.text) return _turnFor(_slot);
    if (_phone == null && _email == null) return _clarify(_t('Please share a phone number or an email.', 'Please ek phone number ya email batao.'));
    return _advance();
  }

  ChatTurn _answerEducationYear(UserAnswer a) {
    final txt = a.kind == AnswerKind.choice || a.kind == AnswerKind.text ? a.text.trim() : '';
    if (txt.toLowerCase().startsWith('something else')) {
      _slot = _Slot.educationText;
      return _turnFor(_slot);
    }
    final year = RegExp(r'(19|20)\d{2}').firstMatch(txt)?.group(0);
    if (year == null) {
      if (a.kind == AnswerKind.skip) return _mustHave();
      return _clarify(_t('Which year do you finish? Tap one, or type it like 2026.', 'Kaun sa saal complete hoga? Button dabao ya 2026 jaisa likho.'));
    }
    _education = [
      ..._education,
      ResumeEducation(degree: _clean(ctx.course)!, institution: _clean(ctx.college)!, duration: _yearLabel(int.parse(year))),
    ];
    return _advance();
  }

  ChatTurn _answerEducationText(UserAnswer a) {
    if (a.kind == AnswerKind.skip) return _mustHave();
    if (a.kind != AnswerKind.text) return _turnFor(_slot);
    final text = a.text.trim();
    final years = RegExp(r'(19|20)\d{2}').allMatches(text).map((m) => m.group(0)!).toList();
    String? gpa;
    final cgpa = RegExp(r'(\d{1,2}(?:\.\d{1,2})?)\s*(cgpa|gpa)', caseSensitive: false).firstMatch(text);
    final pct = RegExp(r'(\d{2,3}(?:\.\d+)?)\s*%').firstMatch(text);
    if (cgpa != null) gpa = '${cgpa.group(1)} CGPA';
    if (gpa == null && pct != null) gpa = '${pct.group(1)}%';
    final parts = text
        .split(RegExp(r'[,\n;]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && !RegExp(r'\d{4}').hasMatch(p) && !RegExp(r'cgpa|gpa|%', caseSensitive: false).hasMatch(p))
        .toList();
    String? degree = parts.isNotEmpty ? parts[0] : null;
    String? institution = parts.length > 1 ? parts[1] : null;
    degree ??= _clean(ctx.course);
    institution ??= _clean(ctx.college);
    // A lone answer is only enough when it fills the one gap left.
    if (parts.length < 2 && !(parts.length == 1 && _knownEducation)) {
      return _clarify(_t('Tell me your degree and college, like: B.Com, Pune University, 2021-2024.', 'Degree aur college batao, jaise: B.Com, Pune University, 2021-2024.'));
    }
    if (parts.length == 1 && _knownEducation) {
      degree = parts[0];
      institution = _clean(ctx.college);
    }
    String duration = '';
    if (years.length >= 2) {
      duration = '${years[0]} - ${years[1]}';
    } else if (years.length == 1) {
      duration = _yearLabel(int.parse(years[0]));
    } else {
      _check.add("I didn't get the years for $degree. Please add them.");
    }
    _education = [..._education, ResumeEducation(degree: degree!, institution: institution!, duration: duration, gpa: gpa)];
    return _advance();
  }

  ChatTurn _answerSkills(UserAnswer a) {
    if (a.kind == AnswerKind.skip) return _mustHave();
    final raw = a.kind == AnswerKind.multi ? a.items : (a.kind == AnswerKind.text || a.kind == AnswerKind.choice ? _splitList(a.text) : <String>[]);
    final items = _splitList(raw.join(',').replaceFirst(RegExp(r'^\s*skills?\s*[:\-]\s*', caseSensitive: false), ''));
    if (items.isEmpty) {
      return _clarify(_t('Pick a few skills, or type them separated by commas.', 'Kuch skills chuno, ya comma lagake likho.'));
    }
    _addSkills(items);
    return _advance();
  }

  ChatTurn _answerExpGate(UserAnswer a) {
    if (a.kind == AnswerKind.text && a.text.trim().length > 12 && !_isNo(a.text)) {
      // They gave the whole answer at once ("intern at Indigo, June 2024").
      _hasExperience = true;
      _slot = _Slot.expDetail;
      return _answerExpDetail(a);
    }
    final yes = a.kind == AnswerKind.yes || (a.kind != AnswerKind.skip && _isYes(a.text));
    final no = a.kind == AnswerKind.no || a.kind == AnswerKind.skip || _isNo(a.text);
    if (yes) {
      _hasExperience = true;
      _queue.insert(0, _Slot.expDetail);
      _enforceCap();
      return _advance();
    }
    if (no) {
      _hasExperience = false;
      return _advance();
    }
    return _clarify(_t('Have you done an internship or a job? Tap Yes or Not yet.', 'Kya aapne internship ya job ki hai? Yes ya Not yet dabao.'));
  }

  ChatTurn _answerExpDetail(UserAnswer a) {
    if (a.kind == AnswerKind.skip || (a.kind == AnswerKind.text && _isNo(a.text))) {
      _hasExperience = _experience.isNotEmpty;
      return _advance();
    }
    if (a.kind != AnswerKind.text) return _turnFor(_slot);
    var text = a.text.trim();
    String duration = '';
    final dur = _durationRegex.firstMatch(text);
    if (dur != null) {
      duration = _tidyDuration(dur.group(0)!);
      text = text.replaceFirst(dur.group(0)!, ' ');
    }
    String? company;
    String? role;
    String rest = '';
    final at = RegExp(r'^(.+?)\s+(?:at|@)\s+(.+?)(?:[,\n].*)?$', caseSensitive: false).firstMatch(text.replaceAll(RegExp(r'\s+'), ' ').trim());
    if (at != null && !text.contains(',')) {
      role = at.group(1)!.trim();
      company = at.group(2)!.trim();
    } else {
      final parts = text.split(RegExp(r'[,\n;]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        company = parts[0];
        role = parts[1];
        rest = parts.skip(2).join('. ');
      } else if (at != null) {
        role = at.group(1)!.trim();
        company = at.group(2)!.trim();
      }
    }
    if (company == null || role == null || company.isEmpty || role.isEmpty) {
      return _clarify(_t('Tell me the company, your role and when — like: Indigo, Ground Staff Intern, Jun-Aug 2024.', 'Company, aapka role aur kab — jaise: Indigo, Ground Staff Intern, Jun-Aug 2024.'));
    }
    if (duration.isEmpty || !RegExp(r'\d{4}').hasMatch(duration)) {
      _check.add("I couldn't find the year for your role at $company. Please add it.");
    }
    final description = _bullets(rest, role);
    _flagHinglish(rest, 'your role at $company');
    _experience = [..._experience, WorkExperience(company: _capFirst(company), role: _capFirst(role), duration: duration, description: description)];
    _hasExperience = true;
    return _advance();
  }

  ChatTurn _answerProjects(UserAnswer a) {
    if (a.kind == AnswerKind.skip || (a.kind == AnswerKind.text && _isNo(a.text))) return _advance();
    if (a.kind != AnswerKind.text) return _turnFor(_slot);
    final lines = a.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).take(3);
    for (final line in lines) {
      String title = line;
      String desc = '';
      final sep = RegExp(r'\s[-–—:]\s|:\s|\.\s').firstMatch(line);
      if (sep != null) {
        title = line.substring(0, sep.start).trim();
        desc = line.substring(sep.end).trim();
      }
      _flagHinglish(line, 'your project');
      _projects = [..._projects, ResumeProject(title: _capFirst(_short(title, 70)), description: _bullets(desc, title))];
    }
    return _advance();
  }

  ChatTurn _answerOther(UserAnswer a) {
    if (a.kind == AnswerKind.skip || (a.kind == AnswerKind.text && _isNo(a.text))) return _advance();
    if (a.kind != AnswerKind.text) return _turnFor(_slot);
    for (final item in a.text.split(RegExp(r'[\n;]')).map((l) => l.trim()).where((l) => l.isNotEmpty).take(4)) {
      _flagHinglish(item, 'your achievements');
      _extras = [..._extras, _capFirst(item)];
    }
    return _advance();
  }

  // ------------------------------------------------------------- stepping

  ChatTurn _advance() {
    _answered++;
    _clarifications.remove(_slot);
    _dropFilledSlots();
    if (_queue.isEmpty) return _doneTurn();
    _slot = _queue.removeAt(0);
    return _turnFor(_slot);
  }

  ChatTurn _mustHave() {
    _notice = _t('I do need this one for your resume.', 'Resume ke liye ye zaroori hai.');
    return _turnFor(_slot);
  }

  /// A multi-fact message may already have answered later questions.
  void _dropFilledSlots() {
    if (_skills.isNotEmpty) _queue.remove(_Slot.skills);
    if (_education.isNotEmpty) {
      _queue.remove(_Slot.educationYear);
      _queue.remove(_Slot.educationText);
    }
    if (_phone != null || _email != null) _queue.remove(_Slot.contact);
    if (_hasExperience != null) _queue.remove(_Slot.expGate);
    if (_projects.isNotEmpty) _queue.remove(_Slot.projects);
    if (_extras.isNotEmpty) _queue.remove(_Slot.other);
  }

  void _enforceCap() {
    // current slot was just answered, so _answered + 1 slots are used.
    while (_answered + 1 + _queue.length > _cap && _queue.isNotEmpty) {
      _queue.removeLast();
    }
  }

  ChatTurn _clarify(String message) {
    final n = (_clarifications[_slot] ?? 0) + 1;
    _clarifications[_slot] = n;
    if (n >= 2) {
      _notice = _t(
        "I'm having trouble understanding this one. Want to use the normal form instead?",
        'Mujhe ye samajh nahi aa raha. Normal form use karein?',
      );
      return _turnFor(_slot, offerForm: true);
    }
    _notice = message;
    return _turnFor(_slot);
  }

  ChatTurn _doneTurn() {
    return ChatTurn(
      message: _t("That's everything I need. Ready to build your resume?", 'Bas, mujhe itna hi chahiye tha. Resume bana dein?'),
      topic: ChatTopic.done,
      answerType: AnswerType.none,
      questionsDone: _answered,
      questionsTotal: _answered,
      readyToBuild: true,
      offerForm: _formOfferPending,
    );
  }

  ChatTurn _turnFor(_Slot s, {bool greeting = false, bool offerForm = false}) {
    final total = _answered + 1 + _queue.length;
    final first = _firstName;
    final hi = greeting && !_fromExisting ? _t('Hi $first! One minute and your resume is ready. ', 'Hi $first! Ek minute mein resume ready. ') : '';
    ChatTurn turn({
      required String message,
      required ChatTopic topic,
      required AnswerType type,
      List<String> choices = const [],
      bool skippable = false,
    }) =>
        ChatTurn(
          message: '$hi$message',
          topic: topic,
          answerType: type,
          choices: choices,
          skippable: skippable,
          questionsDone: _answered,
          questionsTotal: total,
          readyToBuild: _mustHaves,
          offerForm: offerForm,
        );

    switch (s) {
      case _Slot.confirmUpload:
        return ChatTurn(
          message: _foundSummary(),
          topic: ChatTopic.confirm,
          answerType: AnswerType.confirm,
          choices: [_t('Looks right', 'Sahi hai'), _t('Not quite', 'Kuch galat hai')],
          questionsDone: _answered,
          questionsTotal: total,
          readyToBuild: _mustHaves,
          offerForm: offerForm,
        );
      case _Slot.confirmFix:
        return turn(
          message: _t('What should I fix? A few words is enough.', 'Kya theek karna hai? Thoda sa likh do.'),
          topic: ChatTopic.confirm,
          type: AnswerType.text,
          skippable: true,
        );
      case _Slot.contact:
        return turn(
          message: _t('Which phone number or email should recruiters use?', 'Recruiters aapko kis phone number ya email par contact karein?'),
          topic: ChatTopic.contact,
          type: AnswerType.text,
        );
      case _Slot.educationYear:
        final years = [for (var y = _now.year - 1; y <= _now.year + 3; y++) '$y'];
        return turn(
          message: _t(
            'I have ${ctx.course} at ${ctx.college}. Which year do you finish?',
            'Mere paas ${ctx.course}, ${ctx.college} hai. Kaun se saal mein complete hoga?',
          ),
          topic: ChatTopic.education,
          type: AnswerType.choices,
          choices: [...years, _t('Something else', 'Something else')],
        );
      case _Slot.educationText:
        return turn(
          message: _t(
            'What did you study and where? Like: B.Com, Pune University, 2021-2024.',
            'Kya padha aur kahan? Jaise: B.Com, Pune University, 2021-2024.',
          ),
          topic: ChatTopic.education,
          type: AnswerType.text,
        );
      case _Slot.skills:
        return turn(
          message: _t('Which skills do you have? Tap a few, or type your own.', 'Aapke paas kaun si skills hain? Kuch chuno, ya apni likho.'),
          topic: ChatTopic.skills,
          type: AnswerType.multi,
          choices: _skillSuggestions,
        );
      case _Slot.expGate:
        return turn(
          message: _t('Have you done any internship or job?', 'Kya aapne koi internship ya job ki hai?'),
          topic: ChatTopic.experience,
          type: AnswerType.choices,
          choices: ['Yes', 'Not yet'],
        );
      case _Slot.expDetail:
        return turn(
          message: _t(
            'Tell me the company, your role and when. Like: Indigo, Ground Staff Intern, Jun-Aug 2024.',
            'Company, aapka role aur kab batao. Jaise: Indigo, Ground Staff Intern, Jun-Aug 2024.',
          ),
          topic: ChatTopic.experience,
          type: AnswerType.text,
          skippable: true,
        );
      case _Slot.projects:
        return turn(
          message: _t('Any project you are proud of? One line is fine.', 'Koi project jis par aapko garv ho? Ek line kaafi hai.'),
          topic: ChatTopic.projects,
          type: AnswerType.text,
          skippable: true,
        );
      case _Slot.other:
        return turn(
          message: _t('Any award, achievement or activity you want to add?', 'Koi award, achievement ya activity add karni hai?'),
          topic: ChatTopic.other,
          type: AnswerType.text,
          skippable: true,
        );
    }
  }

  String _foundSummary() {
    final bits = <String>[];
    if (_education.isNotEmpty) bits.add('${_education.first.degree}, ${_education.first.institution}');
    if (_skills.isNotEmpty) bits.add('${_skills.length} ${_skills.length == 1 ? 'skill' : 'skills'}');
    if (_experience.isNotEmpty) bits.add('${_experience.length} ${_experience.length == 1 ? 'job or internship' : 'jobs or internships'}');
    if (_projects.isNotEmpty) bits.add('${_projects.length} ${_projects.length == 1 ? 'project' : 'projects'}');
    final found = bits.isEmpty ? _t('your name', 'aapka naam') : bits.join('; ');
    if (ctx.existingIsDraft) {
      return _t('Welcome back! So far I have: $found. Is that right?', 'Welcome back! Abhi tak mere paas hai: $found. Sahi hai?');
    }
    return _t('I read your resume and found: $found. Does that look right?', 'Maine aapka resume padha. Mila: $found. Sahi hai?');
  }

  List<String> get _skillSuggestions {
    final course = _clean(ctx.course);
    var field = courseFieldFor(course);
    if (field == CourseField.general && course != null) field = courseFieldFor(course.split(' ').first);
    return skillSuggestionsByField[field] ?? skillSuggestionsByField[CourseField.general]!;
  }

  // ------------------------------------------------------------- absorbing

  void _absorbContact(String text) {
    final email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').firstMatch(text)?.group(0);
    if (email != null) _email ??= email;
    final phone = RegExp(r'(?:\+?91[\s-]?)?[6-9]\d{9}').firstMatch(text.replaceAll(RegExp(r'[\s-](?=\d)'), ''))?.group(0);
    if (phone != null) _phone ??= phone;
  }

  /// "skills: python, sql" / "projects - x" inside any answer fills that slot too.
  void _absorbLabelled(String text) {
    final skills = RegExp(r'skills?\s*[:\-]\s*([^\n]+)', caseSensitive: false).firstMatch(text);
    if (skills != null && _slot != _Slot.skills) {
      final items = _splitList(skills.group(1)!);
      if (items.isNotEmpty) _addSkills(items);
    }
  }

  void _addSkills(List<String> items) {
    for (final s in items) {
      if (_skills.any((x) => x.toLowerCase() == s.toLowerCase())) continue;
      _skills = [..._skills, s];
    }
  }

  List<String> _splitList(String text) {
    final seen = <String>{};
    final out = <String>[];
    for (var s in text.split(RegExp(r'[,;\n/]|\s+(?:and|aur)\s+', caseSensitive: false))) {
      s = s.trim().replaceAll(RegExp(r'^[-•*]\s*'), '');
      if (s.isEmpty || s.length > 40 || _looksLikeInstruction(s)) continue;
      if (_skipWords.contains(s.toLowerCase())) continue;
      if (seen.add(s.toLowerCase())) out.add(_capFirst(s));
    }
    return out;
  }

  // ------------------------------------------------------------- build

  @override
  ResumeBuildResult build({bool draft = false}) {
    final check = [..._check];
    if (_fromExisting && !ctx.existingIsDraft) {
      check.add('Some details came from your uploaded resume. Please check names and dates.');
    }
    if (_wordingTouched) check.add('I tidied the wording of some points. Please check they still say what you did.');
    final ex = ctx.existing;
    final resume = ParsedResume(
      name: ctx.name,
      headline: _headline,
      phone: _phone,
      education: _education,
      skills: _skills,
      projects: _projects,
      links: _links,
      experienceLevel: _hasExperience == false ? 'Fresher' : ex?.experienceLevel,
      specializations: ex?.specializations ?? const [],
      summary: (ex?.summary?.trim().isNotEmpty ?? false) ? ex!.summary : _summary(),
      workExperience: _experience,
      certifications: _certs,
      portfolioLink: ex?.portfolioLink,
      portfolioFileName: ex?.portfolioFileName,
      achievements: _extras,
      isDraft: draft,
    );
    return ResumeBuildResult(resume: resume, pleaseCheck: check);
  }

  /// Two lines at most, built only from facts the student gave.
  String? _summary() {
    if (_education.isEmpty) return null;
    final e = _education.first;
    final studying = e.duration.startsWith('Expected') || e.duration.contains('Present') || e.duration.isEmpty;
    final b = StringBuffer('${e.degree} ${studying ? 'student' : 'graduate'} at ${e.institution}');
    if (_skills.length >= 2) {
      final top = _skills.take(3).toList();
      b.write(' with skills in ${top.length == 1 ? top[0] : '${top.sublist(0, top.length - 1).join(', ')} and ${top.last}'}');
    }
    if (_experience.isNotEmpty) b.write(', and experience as ${_experience.first.role} at ${_experience.first.company}');
    b.write('.');
    return b.toString();
  }

  // ------------------------------------------------------------- text tools

  String _bullets(String text, String context) {
    final out = <String>[];
    for (var s in text.split(RegExp(r'[.\n;]'))) {
      s = s.trim();
      if (s.isEmpty) continue;
      final before = s;
      s = s.replaceFirst(RegExp(r'^(?:i also|i was|i have|i had|i|my job was to|maine)\s+', caseSensitive: false), '');
      final words = s.split(' ');
      final lead = _verbs[words.first.toLowerCase()];
      if (lead != null) {
        words[0] = lead;
        s = words.join(' ');
      }
      s = _capFirst(s);
      if (s.toLowerCase() != before.toLowerCase()) _wordingTouched = true;
      out.add(s);
      if (out.length == 4) break;
    }
    return out.join('\n');
  }

  void _flagHinglish(String text, String where) {
    if (_hasHinglish(text, strict: true)) {
      _check.add('The text for $where looks like Hinglish: "${_short(text.trim())}". Your resume must be in English, so please rewrite it.');
    }
  }

  String _yearLabel(int year) => year > _now.year ? 'Expected $year' : '$year';

  String _tidyDuration(String raw) {
    var s = raw.replaceAll(RegExp(r'\s*(?:–|—|-|\bto\b|\bse\b)\s*', caseSensitive: false), ' - ').replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.split(' ').map((w) => w == '-' ? w : _capFirst(w)).join(' ');
    return s;
  }

  String _t(String en, String hi) => _hinglish ? hi : en;
  String get _firstName => ctx.name.trim().isEmpty ? 'there' : ctx.name.trim().split(' ').first;
  String? _clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
  String _capFirst(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String _short(String s, [int max = 60]) => s.length <= max ? s : '${s.substring(0, max - 1)}…';
  bool _isNo(String t) => _skipWords.contains(t.trim().toLowerCase().replaceAll(RegExp(r'[.!]+$'), ''));
  bool _isYes(String t) => const {'yes', 'y', 'haan', 'ha', 'han', 'yeah', 'yep', 'ji', 'ji haan'}.contains(t.trim().toLowerCase());

  // ------------------------------------------------------------- detectors

  bool _hasHinglish(String text, {bool strict = false}) {
    final words = text.toLowerCase().split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty);
    var hits = 0;
    for (final w in words) {
      if (_hinglishWords.contains(w)) hits++;
    }
    return strict ? hits >= 2 : hits >= 1;
  }

  bool _looksLikeInstruction(String text) => _injection.hasMatch(text);

  /// Only requests aimed at the bot count ("tell me a joke", "who are you"),
  /// so a resume answer like "built a movie review app" is never blocked.
  bool _isOffTopic(String text) {
    final lower = text.toLowerCase().trim();
    final request = RegExp(r'^(please\s+)?(tell|write|give|show|what|who|how|can you|could you|sing|explain|do you)\b').hasMatch(lower);
    if (!request) return false;
    return _offTopicWords.any(lower.contains) || RegExp(r'\byou(r)?\b').hasMatch(lower);
  }

  static final _injection = RegExp(
    r'(ignore (?:all |your |the |any )?(?:previous |prior |above )?(?:rules|instructions|prompt)|system prompt|you are now|act as |pretend to be|reveal your|disregard (?:all|your|the)|forget (?:all|your|everything))',
    caseSensitive: false,
  );

  static const _offTopicWords = [
    'poem', 'joke', 'weather', 'cricket score', 'recipe', 'movie', 'song lyrics', 'politic', 'bitcoin', 'stock tip',
    'prime minister', 'write code', 'python code', 'homework', 'essay', 'story', 'capital of', 'time is it',
  ];

  static const _hinglishWords = {
    'nahi', 'nhi', 'hai', 'hain', 'hoon', 'hu', 'mera', 'meri', 'mere', 'aur', 'haan', 'kya', 'abhi', 'kiya', 'kaam', 'wala', 'wali',
    'maine', 'karta', 'karti', 'padha', 'padhai', 'kab', 'kahan', 'mujhe', 'bhai', 'bohot', 'bahut', 'thoda', 'sab', 'kuch', 'koi',
  };

  static const _skipWords = {
    'skip', 'none', 'nothing', 'no', 'nope', 'na', 'nahi', 'nhi', 'not yet', 'abhi nahi', 'nahi hai', 'nhi hai', 'abhi nahi hai',
    'koi nahi', "i don't have this yet", 'i dont have this yet', "don't have", 'dont have', 'no experience', 'n/a', 'fresher',
  };

  static final _durationRegex = RegExp(
    r"((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s*'?(?:\d{2,4})?\s*(?:-|–|—|to|se)\s*(?:(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s*'?(?:\d{2,4})?|present|current|now|abhi)|(?:19|20)\d{2}\s*(?:-|–|—|to|se)\s*(?:(?:19|20)\d{2}|present|current|now|abhi)|\d+\s*(?:months?|weeks?|years?|yrs?)|(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s*(?:19|20)\d{2})",
    caseSensitive: false,
  );

  static const _verbs = {
    'handle': 'Handled', 'handling': 'Handled', 'help': 'Helped', 'helping': 'Helped', 'assist': 'Assisted', 'assisting': 'Assisted',
    'manage': 'Managed', 'managing': 'Managed', 'work': 'Worked', 'working': 'Worked', 'make': 'Made', 'making': 'Made',
    'create': 'Created', 'creating': 'Created', 'build': 'Built', 'building': 'Built', 'lead': 'Led', 'leading': 'Led',
    'prepare': 'Prepared', 'preparing': 'Prepared', 'support': 'Supported', 'supporting': 'Supported', 'train': 'Trained',
    'training': 'Trained', 'organise': 'Organised', 'organize': 'Organized', 'organizing': 'Organized', 'coordinate': 'Coordinated',
    'coordinating': 'Coordinated', 'teach': 'Taught', 'teaching': 'Taught', 'design': 'Designed', 'designing': 'Designed',
    'develop': 'Developed', 'developing': 'Developed', 'sell': 'Sold', 'selling': 'Sold', 'write': 'Wrote', 'writing': 'Wrote',
    'test': 'Tested', 'testing': 'Tested', 'check': 'Checked', 'checking': 'Checked', 'clean': 'Cleaned',
  };
}
