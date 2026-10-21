import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_skill_stories.dart';
import '../../models/skill_story.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/not_found_view.dart';
import '../../widgets/responsive_body.dart';

/// Full-screen "soft skills for jobs" mini-quiz — a handful of tap-to-advance
/// scenario questions ending in one concrete takeaway. Mirrors the daily
/// story-card pattern (segmented top progress bar, bold colored background,
/// one prompt at a time) rather than a plain quiz page, since the point is
/// to feel like a quick break, not another form.
class SkillStoryScreen extends StatefulWidget {
  final String id;
  const SkillStoryScreen({super.key, required this.id});

  @override
  State<SkillStoryScreen> createState() => _SkillStoryScreenState();
}

class _SkillStoryScreenState extends State<SkillStoryScreen> {
  int _index = 0;
  int _bestPracticeCount = 0;
  bool _showResult = false;
  int? _pickedOptionIndex;

  @override
  void initState() {
    super.initState();
    // Instagram-style: opening the story is what marks it viewed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().markStoryViewed(widget.id);
    });
  }

  void _pick(SkillStory story, StoryOption option, int optionIndex) {
    if (_pickedOptionIndex != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pickedOptionIndex = optionIndex;
      if (option.isBestPractice) _bestPracticeCount++;
    });
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      if (_index + 1 >= story.pages.length) {
        setState(() => _showResult = true);
      } else {
        setState(() {
          _index++;
          _pickedOptionIndex = null;
        });
      }
    });
  }

  void _close() => context.pop();

  /// Where this story sits among all skill-boost cards, so edge taps can
  /// jump to the sibling story instead of only ever closing — mirrors
  /// tapping between different people's stories on Instagram.
  int get _storyIndex => mockSkillStories.indexWhere((s) => s.id == widget.id);
  String? get _prevStoryId => _storyIndex > 0 ? mockSkillStories[_storyIndex - 1].id : null;
  String? get _nextStoryId =>
      _storyIndex >= 0 && _storyIndex < mockSkillStories.length - 1 ? mockSkillStories[_storyIndex + 1].id : null;

  void _goToPrevStory() {
    final id = _prevStoryId;
    if (id == null) return;
    HapticFeedback.selectionClick();
    context.pushReplacement('/story/$id');
  }

  void _goToNextStory() {
    final id = _nextStoryId;
    if (id == null) {
      // Instagram behavior: tapping forward past the last story just
      // closes the viewer instead of doing nothing.
      _close();
      return;
    }
    HapticFeedback.selectionClick();
    context.pushReplacement('/story/$id');
  }

  @override
  Widget build(BuildContext context) {
    final story = getSkillStoryById(widget.id);
    if (story == null) {
      return const NotFoundView(
        title: 'Story not found',
        message: "This story may have been removed, or the link you followed is out of date.",
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Story backgrounds range from brand yellow to a deep neutral, so the
      // status-bar icon brightness follows the background rather than being fixed.
      value: story.background.computeLuminance() > 0.5 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: story.background,
        body: ResponsiveBody(maxWidth: isTablet ? 560 : AppBreakpoints.maxContentWidth, child: Stack(
          children: [
            // Edge tap zones sit behind all real content — taps that land on
            // an actual button (close icon, an answer option) are caught by
            // that widget's own detector first, so this only ever fires for
            // taps on empty space, exactly like Instagram's story edges.
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _goToPrevStory)),
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _goToNextStory)),
                ],
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                    child: Row(
                      children: List.generate(story.pages.length, (i) {
                        final filled = _showResult || i < _index || (i == _index && _pickedOptionIndex != null);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i == story.pages.length - 1 ? 0 : AppSpacing.xs),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: LinearProgressIndicator(
                                value: filled ? 1 : 0,
                                minHeight: 4,
                                backgroundColor: story.foreground.withValues(alpha: 0.25),
                                valueColor: AlwaysStoppedAnimation(story.foreground),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _close,
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: story.foreground.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Ionicons.close, size: 20, color: story.foreground),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _showResult
                        ? _ResultView(story: story, score: _bestPracticeCount, onDone: _close)
                        : _QuestionView(
                            story: story,
                            page: story.pages[_index],
                            pickedIndex: _pickedOptionIndex,
                            onPick: (opt, i) => _pick(story, opt, i),
                          ),
                  ),
                  SizedBox(height: bottomInset),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final SkillStory story;
  final StoryPage page;
  final int? pickedIndex;
  final void Function(StoryOption option, int index) onPick;

  const _QuestionView({required this.story, required this.page, required this.pickedIndex, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.prompt,
            style: AppTextStyles.h2.copyWith(color: story.foreground, fontWeight: AppFontWeight.semibold, height: 1.3),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: Column(
              children: List.generate(page.options.length, (i) {
                final option = page.options[i];
                final isPicked = pickedIndex == i;
                final revealed = pickedIndex != null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () => onPick(option, i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: revealed && isPicked ? (option.isBestPractice ? AppColors.success : AppColors.gray400) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 16),
                            ),
                          ),
                          if (revealed && isPicked)
                            Icon(
                              option.isBestPractice ? Ionicons.checkmark_circle : Ionicons.ellipse_outline,
                              size: 20,
                              color: option.isBestPractice ? AppColors.success : AppColors.gray400,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final SkillStory story;
  final int score;
  final VoidCallback onDone;

  const _ResultView({required this.story, required this.score, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: story.foreground.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(story.icon, size: 26, color: story.foreground),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Text(
              story.insightTitle,
              style: AppTextStyles.display.copyWith(color: story.foreground, fontWeight: AppFontWeight.semibold, fontSize: 30, height: 1.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              story.insightBody,
              style: AppTextStyles.bodyLg.copyWith(color: story.foreground.withValues(alpha: 0.85), height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: GestureDetector(
              onTap: onDone,
              child: Container(
                height: AppSpacing.xxxl + AppSpacing.sm,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: story.foreground, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text('Got it', style: AppTextStyles.bodyLg.copyWith(color: story.background, fontWeight: AppFontWeight.medium)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
