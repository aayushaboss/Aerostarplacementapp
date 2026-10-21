import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/resume_bot.dart';
import '../../models/parsed_resume.dart';
import '../../services/apply_flow.dart';
import '../../services/resume_chat/chat_models.dart';
import '../../services/resume_chat/llm_resume_engine.dart';
import '../../services/resume_chat/resume_chat_engine.dart';
import '../../services/resume_chat/scripted_resume_engine.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/resume_ready_view.dart';

enum _Phase { chat, review, ready }

class _Msg {
  final bool fromBot;
  final String text;
  const _Msg(this.fromBot, this.text);
}

/// **Resume flow 2**: a chat with the Resume Helper instead of the 7-step quiz.
/// The helper asks one question at a time (typed answers, or buttons for the
/// easy ones), then compiles a resume. Finishes exactly like flow 1: saves,
/// shows [ResumeReadyView], then continues a pending application or goes home.
class ResumeChatScreen extends StatefulWidget {
  final String? applyForOpportunityId;

  /// A freshly uploaded and parsed resume to check, if the student came from
  /// the upload screen.
  final ParsedResume? uploaded;

  const ResumeChatScreen({super.key, this.applyForOpportunityId, this.uploaded});

  @override
  State<ResumeChatScreen> createState() => _ResumeChatScreenState();
}

class _ResumeChatScreenState extends State<ResumeChatScreen> {
  late ResumeChatEngine _engine;
  final _messages = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picked = <String>[];

  // Placeholder until the first reply arrives (the dock stays empty while
  // [_thinking] is true).
  ChatTurn _turn = const ChatTurn(message: '', topic: ChatTopic.other, answerType: AnswerType.none, questionsDone: 0, questionsTotal: 1);
  _Phase _phase = _Phase.chat;
  bool _thinking = false;
  // The last answer could not be sent; the dock offers Try again.
  ({UserAnswer answer, String shown})? _failedSend;
  late ResumeChatContext _ctx;
  bool _saving = false;
  ResumeBuildResult? _result;

  bool get _postOnboarding => context.read<AppState>().user?.onboardingComplete == true;

  bool _started = false;

  /// Starts the chat once the app has loaded the signed-in user. Doing this in
  /// initState broke a refresh on this URL: the bot started before the user
  /// was known and asked for details the app already has.
  void _start() {
    _started = true;
    final user = context.read<AppState>().user;
    final existing = widget.uploaded ?? user?.resume;
    final email = (user?.identifier ?? '').contains('@') ? user!.identifier : null;
    _ctx = ResumeChatContext(
      name: user?.name ?? '',
      phone: user?.phone,
      email: email,
      college: user?.college,
      course: user?.course,
      semester: user?.semester,
      existing: existing,
      existingIsDraft: widget.uploaded == null && (user?.resume?.isDraft ?? false),
    );
    final endpoint = ResumeBotConfig.endpoint;
    _engine = endpoint == null ? ScriptedResumeEngine(_ctx) : LlmResumeEngine(_ctx, endpoint: endpoint);
    unawaited(_begin());
  }

  /// Opens the conversation. If the Claude server cannot be reached (no
  /// server, no API key, offline) the built-in helper takes over seamlessly.
  Future<void> _begin() async {
    setState(() => _thinking = true);
    ChatTurn first;
    try {
      first = await _engine.start();
    } on ResumeBotUnavailable {
      _engine = ScriptedResumeEngine(_ctx);
      first = await _engine.start();
    }
    if (!mounted) return;
    setState(() {
      _turn = first;
      _messages.add(_Msg(true, first.message));
      _thinking = false;
    });
    _scrollDown();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- chatting

  Future<void> _submit(UserAnswer answer, String shown) async {
    // One answer at a time: a double-tap must not feed the engine twice.
    if (_thinking || _phase != _Phase.chat) return;
    HapticFeedback.selectionClick();
    final previous = _turn.message;
    final retrying = _failedSend != null;
    setState(() {
      if (!retrying) _messages.add(_Msg(false, shown));
      _failedSend = null;
      _thinking = true;
      _picked.clear();
      _input.clear();
    });
    _scrollDown();
    ChatTurn next;
    try {
      // A short minimum wait so instant replies from the built-in helper still
      // feel like a conversation; the Claude engine is slower than this anyway.
      final results = await Future.wait<Object?>([
        Future.sync(() => _engine.answer(answer, shown: shown)),
        Future<void>.delayed(const Duration(milliseconds: 450)),
      ]);
      next = results.first as ChatTurn;
    } on ResumeBotUnavailable {
      if (!mounted) return;
      setState(() {
        _messages.add(const _Msg(true, 'Sorry, I lost the connection for a moment.'));
        _failedSend = (answer: answer, shown: shown);
        _thinking = false;
      });
      _scrollDown();
      return;
    }
    if (!mounted) return;
    final notice = _engine.notice;
    setState(() {
      if (notice != null) _messages.add(_Msg(true, notice));
      if (next.message != previous) _messages.add(_Msg(true, next.message));
      _turn = next;
      _thinking = false;
    });
    _scrollDown();
    unawaited(_saveDraft());
  }

  void _scrollDown() {
    // The list is reversed, so the newest message is at offset 0.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  /// Autosave while chatting. Marked as a draft so a half-finished chat never
  /// counts as a finished resume (see [ParsedResume.isDraft]).
  Future<void> _saveDraft() async {
    final snapshot = _engine.draftSnapshot();
    if (!mounted || snapshot == null) return;
    try {
      await context.read<AppState>().updateProfile((current) {
        // Never demote a resume that was already finished to a draft.
        if (current.resume != null && !current.resume!.isDraft) return current;
        return current.copyWith(resume: snapshot);
      });
    } catch (e) {
      debugPrint('ResumeChatScreen: autosave failed - $e');
    }
  }

  void _sendText() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _submit(UserAnswer.text(text), text);
  }

  void _sendMulti() {
    final typed = _input.text.trim();
    final items = [..._picked, if (typed.isNotEmpty) typed];
    if (items.isEmpty) return;
    _submit(UserAnswer.multi(items), items.join(', '));
  }

  // ------------------------------------------------------------- finishing

  Future<void> _review() async {
    if (_thinking) return;
    setState(() {
      _messages.add(const _Msg(true, 'Putting your resume together...'));
      _thinking = true;
    });
    _scrollDown();
    final result = await _engine.build();
    if (!mounted) return;
    setState(() {
      _result = result;
      _thinking = false;
      _phase = _Phase.review;
    });
  }

  Future<bool> _save() async {
    final result = _result;
    if (result == null || _saving) return false;
    setState(() => _saving = true);
    try {
      final wasOnboarding = !_postOnboarding;
      await context.read<AppState>().updateProfile((current) => wasOnboarding
          ? current.copyWith(resume: result.resume, onboardingComplete: true)
          : current.copyWith(resume: result.resume));
      return true;
    } catch (e) {
      debugPrint('ResumeChatScreen: save failed - $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Text("Couldn't save your resume - try again."),
            action: SnackBarAction(label: 'Retry', textColor: AppColors.brand, onPressed: _saveAndFinish),
            persist: false,
          ));
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAndFinish() async {
    if (await _save() && mounted) setState(() => _phase = _Phase.ready);
  }

  Future<void> _saveAndOpenForm() async {
    if (await _save() && mounted) context.pushReplacement(_formRoute());
  }

  String _formRoute() {
    final applyFor = widget.applyForOpportunityId;
    return applyFor == null ? '/college/resume/build' : '/college/resume/build?applyFor=$applyFor';
  }

  void _done() {
    final applyFor = widget.applyForOpportunityId;
    if (applyFor != null) {
      continueApplyAfterResume(context, applyFor);
      return;
    }
    context.go('/tabs');
  }

  void _back() {
    if (_phase == _Phase.review) {
      setState(() => _phase = _Phase.chat);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_postOnboarding ? '/tabs' : '/college/resume');
    }
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!_started) {
      if (app.loading || app.user == null) return const Scaffold(backgroundColor: AppColors.white);
      _start();
    }
    if (_phase == _Phase.ready) {
      return ResumeReadyView(user: app.user, onDone: _done);
    }
    final isTablet = AppBreakpoints.isWide(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        maxWidth: isTablet ? 760 : AppBreakpoints.maxContentWidth,
        child: Column(
          children: [
            PageHeaderBar(title: _phase == _Phase.review ? 'Review your resume' : 'Resume Helper', onBack: _back),
            Expanded(child: _phase == _Phase.review ? _buildReview() : _buildChat()),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    final total = _turn.questionsTotal == 0 ? 1 : _turn.questionsTotal;
    final isDone = _turn.topic == ChatTopic.done;
    final label = isDone ? 'All done' : 'Question ${_turn.questionsDone + 1} of $total';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
          child: Row(
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(end: isDone ? 1 : (_turn.questionsDone / total).clamp(0.04, 1.0)),
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 4,
                      backgroundColor: AppColors.gray100,
                      valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          // Reversed + shrink-wrapped and pinned to the top: the newest message is
          // always at scroll offset 0 (the bottom), so it can never end up hidden
          // behind the input dock, however tall the dock gets.
          child: Align(
            alignment: Alignment.topCenter,
            child: ListView.separated(
              controller: _scroll,
              reverse: true,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                if (_thinking && i == 0) return const _Bubble(fromBot: true, child: _TypingDots());
                final m = _messages[_messages.length - 1 - (_thinking ? i - 1 : i)];
                return _Bubble(
                  fromBot: m.fromBot,
                  child: Text(m.text, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 15, height: 1.4)),
                );
              },
            ),
          ),
        ),
        _buildDock(),
      ],
    );
  }

  Widget _buildDock() {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottom + AppSpacing.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_thinking)
                const SizedBox(height: AppSpacing.xxl)
              else if (_failedSend != null) ...[
                PillButton(label: 'Try again', onPressed: () => _submit(_failedSend!.answer, _failedSend!.shown)),
                const SizedBox(height: AppSpacing.sm),
                PillButton(label: 'Use the normal form', variant: PillVariant.ghost, onPressed: () => context.pushReplacement(_formRoute())),
              ] else ...[
                ..._answerControls(),
                _secondaryRow(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _answerControls() {
    switch (_turn.answerType) {
      case AnswerType.text:
        return [_textRow()];
      case AnswerType.choices:
        return [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _turn.choices.map((c) => AppChip(label: c, onPressed: () => _submit(UserAnswer.choice(c), c))).toList(),
          ),
        ];
      case AnswerType.multi:
        return [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _turn.choices
                .map((c) => AppChip(
                      label: c,
                      selected: _picked.contains(c),
                      showCheck: _picked.contains(c),
                      onPressed: () => setState(() => _picked.contains(c) ? _picked.remove(c) : _picked.add(c)),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: PillInput(controller: _input, placeholder: 'Or type your own', onChanged: (_) => setState(() {}), onSubmitted: (_) => _sendMulti())),
              const SizedBox(width: AppSpacing.sm),
              _sendButton(enabled: _picked.isNotEmpty || _input.text.trim().isNotEmpty, onTap: _sendMulti),
            ],
          ),
        ];
      case AnswerType.confirm:
        final labels = _turn.choices;
        return [
          Row(
            children: [
              Expanded(child: PillButton(label: labels[0], onPressed: () => _submit(const UserAnswer.yes(), labels[0]))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: PillButton(label: labels[1], variant: PillVariant.secondary, onPressed: () => _submit(const UserAnswer.no(), labels[1]))),
            ],
          ),
        ];
      case AnswerType.none:
        return [PillButton(label: 'Build my resume', onPressed: _review)];
    }
  }

  Widget _textRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: PillInput(
            controller: _input,
            placeholder: 'Type your answer',
            maxLines: 3,
            minLines: 1,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _sendButton(enabled: _input.text.trim().isNotEmpty, onTap: _sendText),
      ],
    );
  }

  Widget _sendButton({required bool enabled, required VoidCallback onTap}) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: enabled ? AppColors.brand : AppColors.gray200, shape: BoxShape.circle),
          child: const Icon(Ionicons.arrow_forward, size: 22, color: AppColors.ink),
        ),
      );

  Widget _secondaryRow() {
    final actions = <Widget>[
      if (_turn.skippable) _link('Skip this', () => _submit(const UserAnswer.skip(), 'Skip')),
      if (_turn.readyToBuild && _turn.answerType != AnswerType.none) _link('Build my resume now', _review),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_turn.offerForm)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: PillButton(label: 'Use the normal form', variant: PillVariant.secondary, onPressed: () => context.pushReplacement(_formRoute())),
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Wrap(alignment: WrapAlignment.center, spacing: AppSpacing.xl, runSpacing: AppSpacing.sm, children: actions),
          ),
        if (!_turn.offerForm)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: GestureDetector(
              onTap: () => context.pushReplacement(_formRoute()),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Use the normal form instead',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ),
      ],
    );
  }

  Widget _link(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
        ),
      );

  // ------------------------------------------------------------- review

  Widget _buildReview() {
    final r = _result!;
    final resume = r.resume;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
            children: [
              Text('Here is your resume', style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold)),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
                child: Text(
                  'Everything below comes from your answers. Nothing was made up.',
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                ),
              ),
              if (r.pleaseCheck.isNotEmpty) _checkCard(r.pleaseCheck),
              _section('Name', [resume.name]),
              if ((resume.summary ?? '').isNotEmpty) _section('Summary', [resume.summary!]),
              if (resume.education.isNotEmpty)
                _section('Education', [
                  for (final e in resume.education) '${e.degree}\n${[e.institution, if (e.duration.isNotEmpty) e.duration, if (e.gpa != null) e.gpa!].join('  •  ')}',
                ]),
              if (resume.skills.isNotEmpty) _chips('Skills', resume.skills),
              if (resume.workExperience.isNotEmpty)
                _section('Experience', [
                  for (final w in resume.workExperience) '${w.role}, ${w.company}${w.duration.isEmpty ? '' : '\n${w.duration}'}${w.description.isEmpty ? '' : '\n${w.description}'}',
                ]),
              if (resume.projects.isNotEmpty)
                _section('Projects', [for (final p in resume.projects) p.description.isEmpty ? p.title : '${p.title}\n${p.description}']),
              if (resume.certifications.isNotEmpty) _section('Certificates', [for (final c in resume.certifications) c.duration.isEmpty ? c.name : '${c.name}\n${c.duration}']),
              if (resume.achievements.isNotEmpty) _section('Achievements', resume.achievements),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottom + AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillButton(label: 'Looks good, save', onPressed: _saveAndFinish, loading: _saving),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: PillButton(label: 'Keep chatting', variant: PillVariant.ghost, onPressed: _saving ? null : () => setState(() => _phase = _Phase.chat))),
                  Expanded(child: PillButton(label: 'Fix in form', variant: PillVariant.ghost, onPressed: _saving ? null : _saveAndOpenForm)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkCard(List<String> items) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Ionicons.alert_circle_outline, size: 18, color: AppColors.ink),
                const SizedBox(width: AppSpacing.sm),
                Text('Please check', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final s in items)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('•  $s', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, height: 1.4)),
              ),
          ],
        ),
      );

  Widget _sectionShell(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(title.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 11, letterSpacing: 1, fontWeight: AppFontWeight.semibold)),
            ),
            child,
          ],
        ),
      );

  Widget _section(String title, List<String> entries) => _sectionShell(
        title,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in entries)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Text(e, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, height: 1.45)),
              ),
          ],
        ),
      );

  Widget _chips(String title, List<String> items) => _sectionShell(
        title,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in items)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(s, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.medium)),
              ),
          ],
        ),
      );
}

class _Bubble extends StatelessWidget {
  final bool fromBot;
  final Widget child;
  const _Bubble({required this.fromBot, required this.child});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth > 520 ? 520 : maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: fromBot ? AppColors.offWhite : AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(fromBot ? AppRadius.sm : AppRadius.lg),
          topRight: Radius.circular(fromBot ? AppRadius.lg : AppRadius.sm),
          bottomLeft: const Radius.circular(AppRadius.lg),
          bottomRight: const Radius.circular(AppRadius.lg),
        ),
        border: fromBot ? null : Border.all(color: AppColors.blue, width: 2),
      ),
      child: child,
    );
    if (!fromBot) return Align(alignment: Alignment.centerRight, child: bubble);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
          child: const Icon(Ionicons.document_text_outline, size: 15, color: AppColors.ink),
        ),
        Flexible(child: bubble),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
              decoration: BoxDecoration(
                color: AppColors.gray400.withValues(alpha: ((_c.value * 3 - i) % 3 < 1) ? 1 : 0.35),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
