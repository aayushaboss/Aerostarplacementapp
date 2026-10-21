import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_aptitude.dart';
import '../../models/aptitude.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/brand.dart';
import '../../widgets/quiz_wide_layout.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/app/school/aptitude.tsx (Aptitude).
class AptitudeScreen extends StatefulWidget {
  const AptitudeScreen({super.key});

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> {
  late final PageController _pageController;
  int _index = 0;
  final Map<String, dynamic> _answers = {};
  bool _calculating = false;
  bool _animating = false;
  Timer? _advanceTimer;

  int get _total => mockAptitudeQuestions.length;

  double get _progress {
    if (_total == 0) return 0;
    final current = mockAptitudeQuestions[_index];
    final answered = _answers[current.id] != null ? 1 : 0;
    return (_index + answered) / _total;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _calculating = true);
    final appState = context.read<AppState>();
    try {
      // TODO: replace with real API call
      await appState.updateProfile((current) => current.copyWith(
            aptitudeResults: computeAptitudeResults(_answers),
            aptitudeSkipped: false,
            onboardingComplete: true,
          ));
      await appState.refresh();
      if (!mounted) return;
      context.go('/school/results');
    } catch (_) {
      if (mounted) setState(() => _calculating = false);
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
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
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
    await _exit();
  }

  /// Leaves the test, asking first when answers would be lost.
  Future<void> _exit() async {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (_answers.isEmpty) {
      context.pop();
      return;
    }
    // At least one question answered and about to actually leave — ask
    // first, mirroring the confirm-before-leaving guard the resume
    // builder already uses for its own in-progress-work case. Previously
    // this just popped silently, discarding every answer with zero
    // warning.
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Leave without finishing?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold)),
        content: Text(
          "Your answers so far won't be saved.",
          style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Keep answering', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Leave', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: AppFontWeight.bold)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  void _answer(dynamic value) {
    if (_calculating || _animating) return;
    // A second tap on a different option within the 220ms window used to
    // be silently ignored (the whole method returned early whenever a
    // timer was already pending) — the first, possibly mis-tapped answer
    // is what got recorded with no way to correct it short of going back
    // a full question. Cancel and reschedule against the new answer
    // instead, so a fast correction actually takes.
    _advanceTimer?.cancel();
    HapticFeedback.lightImpact();
    final questionId = mockAptitudeQuestions[_index].id;
    setState(() => _answers[questionId] = value);

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

  /// Tablet and desktop: the shared quiz layout (a context rail beside the question on an
  /// expanded window, one centred column on a medium one).
  Widget _buildWide(BuildContext context) {
    final q = mockAptitudeQuestions[_index];
    final value = _answers[q.id];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final isSlider = q.type == AptitudeQuestionType.slider;
    return PopScope(
      canPop: _index == 0 && _answers.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: QuizWideLayout(
          eyebrow: 'APTITUDE TEST',
          title: 'Find what fits you',
          index: _index,
          total: _total,
          progress: _progress,
          exitLabel: 'Exit test',
          onExit: _exit,
          helper: 'There are no right or wrong answers. Pick what feels like you.',
          question: q.text,
          options: isSlider
              ? const []
              : [for (var i = 0; i < (q.options ?? const <String>[]).length; i++) QuizOption(key: letters[i % letters.length], label: q.options![i], selected: value == q.options![i], onTap: () => _answer(q.options![i]))],
          answerArea: isSlider ? _SliderAnswer(question: q, value: value, onAnswer: _answer) : null,
          onPrevious: _index > 0 ? _goBack : null,
          onNext: value == null
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
                  const BrandMark(size: (AppSpacing.xxxl + AppSpacing.xxl) * 0.5, onBrand: true),
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  ),
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
                      'Matching your answers to career clusters',
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

    if (isTablet) return _buildWide(context);

    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      // False whenever leaving would either skip questions (mid-way
      // through) or discard at least one already-answered question at
      // index 0 — both routed through _goBack(), which now also confirms
      // before actually discarding answered progress.
      canPop: _index == 0 && _answers.isEmpty,
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
                      'Q${_index + 1} of $_total',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.regular),
                    ),
                  ),
                  SizedBox(width: 44 - AppSpacing.lg),
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
                  final question = mockAptitudeQuestions[i];
                  return _QuestionBody(
                    question: question,
                    answers: _answers,
                    onAnswer: _answer,
                  );
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
  final AptitudeQuestion question;
  final Map<String, dynamic> answers;
  final ValueChanged<dynamic> onAnswer;

  const _QuestionBody({required this.question, required this.answers, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final isTablet = AppBreakpoints.isWide(context);
    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            textAlign: TextAlign.left,
            style: AppTextStyles.h1.copyWith(
              color: AppColors.ink,
              fontWeight: AppFontWeight.medium,
              height: 1.25,
            ),
          ),
          if (question.type == AptitudeQuestionType.single) _buildSingle(),
          if (question.type == AptitudeQuestionType.forced) _buildForced(),
          if (question.type == AptitudeQuestionType.slider) _buildSlider(),
        ],
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
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

  Widget _buildSingle() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: (question.options ?? []).map((opt) {
          final selected = answers[question.id] == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () => onAnswer(opt),
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
                      child: Text(
                        opt,
                        textAlign: TextAlign.left,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: selected ? AppColors.white : AppColors.ink,
                          fontWeight: selected ? AppFontWeight.semibold : AppFontWeight.medium,
                        ),
                      ),
                    ),
                    if (selected) const Icon(Ionicons.checkmark_circle, size: 20, color: AppColors.white),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForced() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (question.options ?? []).map((opt) {
          final selected = answers[question.id] == opt;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: opt == question.options!.last ? 0 : AppSpacing.md),
              child: GestureDetector(
                onTap: () => onAnswer(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  constraints: BoxConstraints(minHeight: AppSpacing.xxxl * 3 + AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blue : AppColors.offWhite,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                    boxShadow: selected ? null : AppShadows.soft,
                  ),
                  child: Text(
                    opt,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h3.copyWith(
                      color: selected ? AppColors.white : AppColors.ink,
                      fontWeight: selected ? AppFontWeight.semibold : AppFontWeight.medium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 3, 4, 5].map((v) {
              final selected = answers[question.id] == v;
              final size = 40 + v * AppSpacing.xs + AppSpacing.xs / 2;
              return GestureDetector(
                onTap: () => onAnswer(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blue : AppColors.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                  ),
                  child: Text(
                    '$v',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: selected ? AppColors.white : AppColors.gray500,
                      fontWeight: selected ? AppFontWeight.semibold : AppFontWeight.medium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(question.minLabel ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontWeight: AppFontWeight.medium)),
                Text(question.maxLabel ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontWeight: AppFontWeight.medium)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 1-5 scale of a slider question, for the wide quiz layout: five round choices with the end labels.
class _SliderAnswer extends StatelessWidget {
  final AptitudeQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onAnswer;
  const _SliderAnswer({required this.question, required this.value, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final v in [1, 2, 3, 4, 5])
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onAnswer(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == v ? AppColors.white : AppColors.offWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: value == v ? AppColors.blue : AppColors.offWhite, width: 2),
                    ),
                    child: Text('$v', style: AppTextStyles.bodyLg.copyWith(color: value == v ? AppColors.ink : AppColors.gray500, fontWeight: value == v ? AppFontWeight.semibold : AppFontWeight.medium)),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(question.minLabel ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
              Text(question.maxLabel ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
            ],
          ),
        ),
      ],
    );
  }
}
