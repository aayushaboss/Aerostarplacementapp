// Prototype mock content — delete when a real content pipeline exists.
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/skill_story.dart';
import '../theme/colors.dart';

final List<SkillStory> mockSkillStories = [
  SkillStory(
    id: 'interview-basics',
    cardTitle: 'Ace your\nfirst interview',
    badge: 'QUIZ',
    background: AppColors.blue,
    foreground: AppColors.white,
    icon: Ionicons.chatbubbles_outline,
    pages: const [
      StoryPage(
        prompt: '"Tell me about yourself" — what\'s the strongest way to open?',
        options: [
          StoryOption(label: 'Recite my whole resume line by line'),
          StoryOption(label: 'A short summary of who I am and why I fit this role', isBestPractice: true),
          StoryOption(label: 'Just talk about my hobbies'),
        ],
      ),
      StoryPage(
        prompt: "You don't know the answer to a technical question. What now?",
        options: [
          StoryOption(label: "Say 'I don't know' and go quiet"),
          StoryOption(label: 'Guess confidently and hope it lands'),
          StoryOption(label: 'Walk through how you\'d figure it out', isBestPractice: true),
        ],
      ),
      StoryPage(
        prompt: "The interview's wrapping up. What's the best way to end it?",
        options: [
          StoryOption(label: 'Thank them and ask what happens next', isBestPractice: true),
          StoryOption(label: 'Just say bye and log off'),
          StoryOption(label: 'Ask about salary right away'),
        ],
      ),
    ],
    insightTitle: 'Interview instinct: sharp',
    insightBody: 'Confident, honest, and curious beats "knowing everything" every time — interviewers remember how you think, not just what you know.',
  ),
  SkillStory(
    id: 'professional-email',
    cardTitle: 'Write a\nprofessional email',
    badge: 'QUIZ',
    background: AppColors.blueDeep,
    foreground: AppColors.white,
    icon: Ionicons.mail_outline,
    pages: const [
      StoryPage(
        prompt: 'Best subject line for a job application email?',
        options: [
          StoryOption(label: '"hi"'),
          StoryOption(label: 'Application for Digital Marketing Intern — Aayusha Sharma', isBestPractice: true),
          StoryOption(label: 'URGENT!!! PLEASE READ'),
        ],
      ),
      StoryPage(
        prompt: 'How should you sign off?',
        options: [
          StoryOption(label: 'Your full name, no closing line'),
          StoryOption(label: '"Regards" + your full name and phone number', isBestPractice: true),
          StoryOption(label: 'A casual emoji 👍'),
        ],
      ),
      StoryPage(
        prompt: "You haven't heard back in a week. What do you do?",
        options: [
          StoryOption(label: 'Send one short, polite follow-up', isBestPractice: true),
          StoryOption(label: 'Email every day until they reply'),
          StoryOption(label: 'Assume it\'s a no and move on silently'),
        ],
      ),
    ],
    insightTitle: 'Inbox-ready',
    insightBody: 'Clear subject, polite tone, one follow-up — that\'s all a professional email needs. Recruiters skim fast; make the first line count.',
  ),
  SkillStory(
    id: 'handling-rejection',
    cardTitle: 'Handling\nrejection like a pro',
    badge: 'MINDSET',
    background: AppColors.warning,
    foreground: AppColors.ink,
    icon: Ionicons.trending_up_outline,
    pages: const [
      StoryPage(
        prompt: "You just got turned down for a role you really wanted. What's the smartest next move?",
        options: [
          StoryOption(label: 'Stop applying for a while'),
          StoryOption(label: 'Apply to two more roles this week and keep momentum', isBestPractice: true),
          StoryOption(label: 'Take it as proof you\'re not good enough'),
        ],
      ),
      StoryPage(
        prompt: 'A friend got an offer and you didn\'t. How do you think about it?',
        options: [
          StoryOption(label: 'Compare yourself to them constantly'),
          StoryOption(label: 'Their timeline isn\'t yours — stay focused on your own applications', isBestPractice: true),
          StoryOption(label: 'Give up on that industry entirely'),
        ],
      ),
    ],
    insightTitle: 'Resilience: building',
    insightBody: "One company's decision is one narrow snapshot, not a verdict on you. The students who land offers are usually just the ones who kept applying after a no.",
  ),
  SkillStory(
    id: 'body-language',
    cardTitle: 'Body language\nthat works for you',
    badge: 'TIPS',
    background: AppColors.success,
    foreground: AppColors.white,
    icon: Ionicons.happy_outline,
    pages: const [
      StoryPage(
        prompt: 'In an interview, what should you do with your hands?',
        options: [
          StoryOption(label: 'Keep them still in your lap or use light natural gestures', isBestPractice: true),
          StoryOption(label: 'Fidget with a pen the whole time'),
          StoryOption(label: 'Cross your arms tightly'),
        ],
      ),
      StoryPage(
        prompt: 'How much eye contact is right on a video call?',
        options: [
          StoryOption(label: 'Stare at the screen without blinking'),
          StoryOption(label: 'Look at the camera occasionally, not just the little face on screen', isBestPractice: true),
          StoryOption(label: 'Avoid it — look down mostly'),
        ],
      ),
    ],
    insightTitle: 'Presence: on point',
    insightBody: 'Calm hands, a steady posture, and glancing at the camera (not just the screen) make you read as confident — even over video.',
  ),
];

SkillStory? getSkillStoryById(String id) {
  try {
    return mockSkillStories.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}
