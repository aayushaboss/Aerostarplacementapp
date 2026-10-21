import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../mockData/career_dna/career_dna_registry.dart';
import '../../../models/career_dna.dart';
import '../../../models/career_dna_question.dart';
import '../../../state/app_state.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/quiz_wide_layout.dart';
import '../../../widgets/responsive_body.dart';

/// The one-question-per-page quiz shell, shared by all 5 Career DNA levels.
/// Mirrors aptitude_screen.dart's mechanics wholesale (PageController +
/// NeverScrollableScrollPhysics, in-memory answers only, 220ms auto-advance
/// timer, back-chevron, leave-confirmation dialog, PopScope) with one
/// deliberate deviation: the status label reads "40% complete" (percent
/// text), per the user's explicit ask, not aptitude_screen.dart's own
/// "Q3 of 20" counter style. Answers are genuinely never persisted until
/// the final submit — quitting mid-quiz loses all progress on this level,
/// by design (see the plan's persistence-discipline note).
class CareerDnaQuizScreen extends StatefulWidget {
  final int level;
  const CareerDnaQuizScreen({super.key, required this.level});

  @override
  State<CareerDnaQuizScreen> createState() => _CareerDnaQuizScreenState();
}

class _CareerDnaQuizScreenState extends State<CareerDnaQuizScreen> {
  late final PageController _pageController;
  late final List<CareerDnaQuestion> _questions;
  int _index = 0;
  final Map<String, String> _answers = {};
  bool _calculating = false;
  bool _animating = false;
  Timer? _advanceTimer;

  int get _total => _questions.length;

  double get _progress {
    if (_total == 0) return 0;
    final current = _questions[_index];
    final answered = _answers[current.id] != null ? 1 : 0;
    return (_index + answered) / _total;
  }

  String get _progressKey => 'career_dna_l${widget.level}_progress';

  @override
  void initState() {
    super.initState();
    _questions = careerDnaQuestionsForLevel(widget.level);
    _pageController = PageController();
    _restoreProgress();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Answers are held only in memory during the quiz, so a browser refresh
  // (or an accidental tab close) mid-way through an 18-25 minute level used
  // to wipe everything. Now every answer is mirrored to SharedPreferences
  // and restored on re-entry; cleared on submit and on a confirmed quit.
  Future<void> _restoreProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw == null || !mounted) return;
      final validIds = _questions.map((q) => q.id).toSet();
      final saved = (jsonDecode(raw) as Map).cast<String, String>()..removeWhere((k, _) => !validIds.contains(k));
      if (saved.isEmpty) return;
      final resumeIndex = saved.length.clamp(0, _total - 1);
      setState(() {
        _answers.addAll(saved);
        _index = resumeIndex;
      });
      void jump() {
        if (mounted && _pageController.hasClients) _pageController.jumpToPage(resumeIndex);
      }
      if (_pageController.hasClients) {
        jump();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => jump());
      }
    } catch (_) {
      // Corrupt / incompatible saved progress — just start fresh.
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_progressKey, jsonEncode(_answers));
    } catch (_) {}
  }

  Future<void> _clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _calculating = true);
    final appState = context.read<AppState>();
    try {
      final current = appState.user?.careerDnaOrEmpty ?? const CareerDnaProfile();
      final updated = computeAndApplyCareerDnaLevel(widget.level, _answers, current);
      await appState.updateProfile((u) => u.copyWith(careerDna: updated));
      await _clearProgress();
      if (!mounted) return;
      context.go('/college/career-dna/level/${widget.level}/complete');
    } catch (_) {
      if (mounted) {
        setState(() => _calculating = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text("Couldn't save your results — try that last answer again.")));
      }
    }
  }

  Future<void> _goTo(int page) async {
    if (_animating || page == _index || page < 0 || page >= _total) return;
    // The wide layout shows one question at a time without a PageView to animate.
    if (!_pageController.hasClients) {
      setState(() => _index = page);
      return;
    }
    setState(() => _animating = true);
    await _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    if (!mounted) return;
    setState(() {
      _index = page;
      _animating = false;
    });
  }

  Future<void> _goBack() async {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (_index > 0) {
      _goTo(_index - 1);
      return;
    }
    if (_answers.isEmpty) {
      _exitToCareerQuiz();
      return;
    }
    await _confirmQuit();
  }

  /// Every way of leaving this screen — the chevron at question 1 with
  /// nothing answered yet, or a confirmed "Leave" from the quit dialog —
  /// lands back on the Career Quiz landing/level-map, not the level's own
  /// intro screen. A plain context.pop() would land on the intro screen
  /// (this route is always reached via push from there), which read as
  /// "quitting" only got you one screen back rather than actually out of
  /// the level — per direct feedback, quitting should always feel like a
  /// full exit.
  void _exitToCareerQuiz() {
    _clearProgress();
    if (mounted) context.go('/tabs/career-dna');
  }

  /// Reachable from any question, not just index 0 — without this, quitting
  /// from deep in a 20-question level meant stepping back one question at
  /// a time via the chevron until reaching the start. Triggered by the
  /// small, deliberately low-key "Exit" control (see build()) rather than
  /// the back-chevron itself, so it's genuinely available without reading
  /// as an invitation to quit.
  Future<void> _confirmQuit() async {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(noOrphan('Are you sure you want to quit?'), style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold)),
        content: Text(
          noOrphan("You'll lose your progress on this level."),
          style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Continue', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Leave', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: AppFontWeight.bold)),
          ),
        ],
      ),
    );
    if (leave == true) _exitToCareerQuiz();
  }

  void _answer(String optionId) {
    if (_calculating || _animating) return;
    _advanceTimer?.cancel();
    HapticFeedback.lightImpact();
    final questionId = _questions[_index].id;
    setState(() => _answers[questionId] = optionId);
    _saveProgress();

    _advanceTimer = Timer(const Duration(milliseconds: 220), () async {
      _advanceTimer = null;
      if (!mounted) return;
      if (_index + 1 >= _total) {
        _submit();
      } else {
        await _goTo(_index + 1);
      }
    });
  }

  /// Tablet and desktop: a focus screen with no navigation. On an expanded window a context
  /// rail (level, progress) sits beside the question and answers are a 2-column grid; on a medium
  /// window it is one centred column with the progress bar across the top.
  Widget _buildWide(BuildContext context) {
    final question = _questions[_index];
    final meta = careerDnaLevelMeta.firstWhere((m) => m.level == widget.level);
    final selected = _answers[question.id];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: QuizWideLayout(
          eyebrow: 'LEVEL ${widget.level}',
          title: meta.title,
          index: _index,
          total: _total,
          progress: _progress,
          exitLabel: 'Exit quiz',
          onExit: _confirmQuit,
          helper: 'There are no right or wrong answers. Pick what you would actually do.',
          question: question.text,
          options: [for (var i = 0; i < question.options.length; i++) QuizOption(key: letters[i % letters.length], label: question.options[i].text, selected: selected == question.options[i].id, onTap: () => _answer(question.options[i].id))],
          onPrevious: _index > 0 ? _goBack : null,
          onNext: selected == null
              ? null
              : () {
                  _advanceTimer?.cancel();
                  _advanceTimer = null;
                  if (_index + 1 >= _total) {
                    _submit();
                  } else {
                    _goTo(_index + 1);
                  }
                },
          isLast: _index + 1 >= _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppBreakpoints.isWide(context);
    if (_calculating) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.blue,
          body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 3)),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Text(
                      'Calculating your results…',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: AppFontWeight.medium),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      noOrphan('Matching your answers to your natural style'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.whiteA70),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ),
      );
    }

    if (_total == 0) {
      // Defensive only — sequential unlocking should make this unreachable.
      return Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text("This level isn't available yet.", style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          ),
        )),
      );
    }

    if (isTablet) return _buildWide(context);

    final topInset = MediaQuery.of(context).padding.top;
    final percentComplete = (_progress * 100).round();

    return PopScope(
      // Always intercepted (never a bare system pop) so a browser/OS back
      // gesture goes through the same _goBack() routing as the in-app
      // chevron — including landing on the Career Quiz tab, not the
      // level's intro screen, when there's nothing to lose yet.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: isTablet ? AppColors.offWhite : AppColors.white,
          body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _goBack,
                      child: const Icon(Ionicons.chevron_back, size: 44 - AppSpacing.lg, color: AppColors.ink),
                    ),
                    Expanded(
                      child: Text(
                        // A bare "0% complete" on the very first question
                        // reads as discouraging before the student has even
                        // started — showing real progress only once there
                        // is some keeps the label motivating instead of
                        // deflating.
                        percentComplete == 0 ? "Let's begin" : '$percentComplete% complete',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.regular),
                      ),
                    ),
                    // Deliberately small and low-contrast (gray, no fill/
                    // border) rather than a prominent button — genuinely
                    // available from any question so quitting deep into a
                    // level doesn't mean stepping back one question at a
                    // time, but not visually competing with "keep going."
                    GestureDetector(
                      onTap: _confirmQuit,
                      child: const SizedBox(
                        width: 44 - AppSpacing.lg,
                        height: 44 - AppSpacing.lg,
                        child: Icon(Ionicons.close, size: 20, color: AppColors.gray400),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _progress.clamp(0.04, 1.0)),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: AppSpacing.sm - AppSpacing.xs / 2,
                      backgroundColor: AppColors.gray100,
                      valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _total,
                  onPageChanged: (page) {
                    if (_index != page) setState(() => _index = page);
                  },
                  itemBuilder: (context, i) {
                    final question = _questions[i];
                    return _QuestionBody(question: question, answers: _answers, onAnswer: _answer);
                  },
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  final CareerDnaQuestion question;
  final Map<String, String> answers;
  final ValueChanged<String> onAnswer;

  const _QuestionBody({required this.question, required this.answers, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final isTablet = AppBreakpoints.isWide(context);
    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 19px, not h1's default 22px — the full-size heading style read
          // as oversized for a single question repeated 20 times in a row;
          // still clearly the largest text on screen, just not "huge."
          //
          // Wrapped in a fixed-height, top-aligned box instead of letting
          // the Column size to whatever this particular question's text
          // needs — per direct feedback, the options were shifting up and
          // down between questions because a 1-line question and a 5-line
          // question left very different amounts of space above the fixed
          // gap that followed them. 140px comfortably covers the longest
          // question actually authored across all 5 levels (confirmed by
          // scanning every question: the longest is 150 characters and
          // wraps to 5 lines at this font size), so short questions just
          // leave blank space below them — that's the deliberate tradeoff
          // that keeps the options landing at the same Y every time.
          SizedBox(
            height: 140,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                noOrphan(question.text),
                textAlign: TextAlign.left,
                style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.medium, height: 1.3),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: question.options.map((opt) {
                final selected = answers[question.id] == opt.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () => onAnswer(opt.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue : AppColors.offWhite,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            // Options are trimmed hard to fit one line at
                            // this button's normal text size (see
                            // career_dna_level1_data.dart) — deliberately
                            // not force-shrunk to fit (that would make some
                            // options read visibly smaller than others,
                            // which looks worse than the rare unavoidable
                            // 2-line wrap this trimming can't always avoid).
                            child: Text(
                              opt.text,
                              textAlign: TextAlign.left,
                              style: AppTextStyles.bodyLg.copyWith(color: selected ? AppColors.white : AppColors.ink, fontWeight: AppFontWeight.medium),
                            ),
                          ),
                          // Fixed-width slot, always present (not just when
                          // selected) — the checkmark appearing on tap used
                          // to shrink the Expanded text's available width by
                          // exactly its own size, which could push text
                          // that fit on one line into a second line the
                          // instant it was selected. Reserving this space
                          // unconditionally keeps the text's width constant
                          // whether an option is selected or not.
                          SizedBox(
                            width: 20 + AppSpacing.sm,
                            child: selected ? const Icon(Ionicons.checkmark_circle, size: 20, color: AppColors.white) : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
          ),
        ],
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
          child: isTablet
              ? Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.soft,
                  ),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
