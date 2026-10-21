import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../mockData/mock_skill_stories.dart';
import '../models/skill_story.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

const double _cardWidth = 122;
const double _cardHeight = 140;
const double _ringGap = 3;
const double _ringWidth = 2.2;

/// Flo-style horizontal "daily insight" strip, repurposed for job-readiness
/// soft skills instead of health facts — a colorful card teaser that opens
/// a 2–4 question story, not a course to sit through. Sized to sit closer
/// to a thumbnail than a full card, so five-plus are visible at once.
class SkillStoryStrip extends StatelessWidget {
  const SkillStoryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text('Skill boosts', style: AppTextStyles.h3.copyWith(color: AppColors.ink)),
        ),
        SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.sm),
            scrollDirection: Axis.horizontal,
            itemCount: mockSkillStories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => _StoryCard(
              story: mockSkillStories[i],
              viewed: appState.isStoryViewed(mockSkillStories[i].id),
            ),
          ),
        ),
      ],
    );
  }
}

/// Calm by design: a fully saturated background per card read as a loud,
/// cluttered rainbow strip; a plain off-white card blended into the page;
/// a different ring color per card looked inconsistent rather than
/// organized. One shared brand identity (ring + tint) for every card, same
/// as the first "Ace your first interview" card — topic color is kept
/// only on the icon inside, not the card's outer look. An Instagram-style
/// outer ring — bold brand-yellow when unread, muted gray once opened — still
/// carries the viewed/unviewed signal.
class _StoryCard extends StatelessWidget {
  final SkillStory story;
  final bool viewed;
  const _StoryCard({required this.story, required this.viewed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/story/${story.id}'),
      child: Container(
        width: _cardWidth,
        height: _cardHeight,
        padding: const EdgeInsets.all(_ringGap),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg + _ringGap),
          border: Border.all(
            color: viewed ? AppColors.gray200 : AppColors.blue,
            width: viewed ? 1.5 : _ringWidth,
          ),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: Icon(story.icon, size: 13, color: story.background),
              ),
              Text(
                story.cardTitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
