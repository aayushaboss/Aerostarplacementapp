import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';

/// One tappable choice on a story question. [isBestPractice] drives the
/// end-of-story score — not a pass/fail grade, just a light nudge toward
/// the stronger habit, shown after the pick so it still teaches something
/// even in a quiz that "has no wrong answers".
class StoryOption {
  final String label;
  final bool isBestPractice;
  final String? note;
  const StoryOption({required this.label, this.isBestPractice = false, this.note});

  Map<String, dynamic> toJson() => {'label': label, 'isBestPractice': isBestPractice, 'note': note};

  factory StoryOption.fromJson(Map<String, dynamic> json) => StoryOption(
        label: json['label'] as String,
        isBestPractice: json['isBestPractice'] as bool? ?? false,
        note: json['note'] as String?,
      );
}

class StoryPage {
  final String prompt;
  final List<StoryOption> options;
  const StoryPage({required this.prompt, required this.options});

  Map<String, dynamic> toJson() => {'prompt': prompt, 'options': options.map((o) => o.toJson()).toList()};

  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
        prompt: json['prompt'] as String,
        options: (json['options'] as List).map((o) => StoryOption.fromJson(o as Map<String, dynamic>)).toList(),
      );
}

/// [icon]/[background]/[foreground] serialize as named tokens (never a raw
/// icon codepoint or ARGB int) — a backend-driven content feed should send
/// semantic names like the app's own theme/icon set already uses, not
/// platform-specific values that'd break across icon font versions.
const _iconTokens = <String, IconData>{
  'chatbubbles': Ionicons.chatbubbles_outline,
  'mail': Ionicons.mail_outline,
  'trending_up': Ionicons.trending_up_outline,
  'happy': Ionicons.happy_outline,
};

const _colorTokens = <String, Color>{
  'blue': AppColors.blue,
  'blueDeep': AppColors.blueDeep,
  'warning': AppColors.warning,
  'success': AppColors.success,
  'white': AppColors.white,
  'ink': AppColors.ink,
};

String _iconToToken(IconData icon) =>
    _iconTokens.entries.firstWhere((e) => e.value == icon, orElse: () => const MapEntry('chatbubbles', Ionicons.chatbubbles_outline)).key;

String _colorToToken(Color color) =>
    _colorTokens.entries.firstWhere((e) => e.value == color, orElse: () => const MapEntry('blue', AppColors.blue)).key;

/// A short, swipeable "soft skills for jobs" story — mirrors the
/// Flo-style daily-insight card pattern: a colorful teaser card on the
/// home feed opens a full-screen 2–4 question mini-quiz ending in one
/// concrete takeaway, not a lesson.
class SkillStory {
  final String id;
  final String cardTitle;
  final String badge;
  final Color background;
  final Color foreground;
  final IconData icon;
  final List<StoryPage> pages;
  final String insightTitle;
  final String insightBody;

  const SkillStory({
    required this.id,
    required this.cardTitle,
    required this.badge,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.pages,
    required this.insightTitle,
    required this.insightBody,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardTitle': cardTitle,
        'badge': badge,
        'background': _colorToToken(background),
        'foreground': _colorToToken(foreground),
        'icon': _iconToToken(icon),
        'pages': pages.map((p) => p.toJson()).toList(),
        'insightTitle': insightTitle,
        'insightBody': insightBody,
      };

  factory SkillStory.fromJson(Map<String, dynamic> json) => SkillStory(
        id: json['id'] as String,
        cardTitle: json['cardTitle'] as String,
        badge: json['badge'] as String,
        background: _colorTokens[json['background'] as String] ?? AppColors.blue,
        foreground: _colorTokens[json['foreground'] as String] ?? AppColors.ink,
        icon: _iconTokens[json['icon'] as String] ?? Ionicons.chatbubbles_outline,
        pages: (json['pages'] as List).map((p) => StoryPage.fromJson(p as Map<String, dynamic>)).toList(),
        insightTitle: json['insightTitle'] as String,
        insightBody: json['insightBody'] as String,
      );
}
