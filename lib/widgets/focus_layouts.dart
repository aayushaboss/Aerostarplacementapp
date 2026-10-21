import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'app_page.dart';
import 'back_chevron.dart';
import 'pill_button.dart';

/// A small label under an icon in [FocusIntroLayout]: "10 minutes", "20 questions".
class FocusTile {
  final IconData icon;
  final String label;
  const FocusTile({required this.icon, required this.label});
}

/// The intro screen of a test (a Career Quiz level, the school aptitude test) on a tablet or
/// desktop window: a focus screen with no navigation, the content in one centred 520px column
/// with the buttons right under it (not stranded at the bottom edge of a big window).
class FocusIntroLayout extends StatelessWidget {
  final IconData icon;
  final String? eyebrow;
  final String title;
  final String subtitle;
  final List<FocusTile> tiles;
  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String backFallback;

  const FocusIntroLayout({
    super.key,
    required this.icon,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    this.tiles = const [],
    required this.primaryLabel,
    this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.backFallback = '/tabs',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl - 8, AppSpacing.xl + 8, AppSpacing.xxl - 8, 0),
          child: Align(alignment: Alignment.centerLeft, child: BackChevron(color: AppColors.ink, fallbackRoute: backFallback)),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 72, height: 72, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle), child: Icon(icon, size: 32, color: AppColors.blue)),
                    if (eyebrow != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: Text(eyebrow!.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 1.4))),
                    Padding(padding: EdgeInsets.only(top: eyebrow != null ? AppSpacing.sm : AppSpacing.lg), child: Text(title, style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 26, height: 1.25))),
                    Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, height: 1.5))),
                    if (tiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: Row(
                          children: [
                            for (var i = 0; i < tiles.length; i++) ...[
                              if (i > 0) const SizedBox(width: AppSpacing.md - 4),
                              Expanded(
                                child: TintCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(tiles[i].icon, size: 20, color: AppColors.ink),
                                      Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(tiles[i].label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.semibold))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Padding(padding: const EdgeInsets.only(top: AppSpacing.xxl - 8), child: PillButton(label: primaryLabel, icon: primaryIcon, onPressed: onPrimary)),
                    if (secondaryLabel != null)
                      Center(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onSecondary,
                            child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md), child: Text(secondaryLabel!, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold))),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A centred "done" screen on a wide window: a mark, a title, a line of text and one or two
/// buttons together under it.
class FocusMessageLayout extends StatelessWidget {
  final Widget mark;
  final Widget title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const FocusMessageLayout({super.key, required this.mark, required this.title, required this.message, required this.primaryLabel, required this.onPrimary, this.secondaryLabel, this.onSecondary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: mark),
              const SizedBox(height: AppSpacing.xl),
              Center(child: title),
              Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(message, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 16))),
              Padding(padding: const EdgeInsets.only(top: AppSpacing.xxl - 8), child: PillButton(label: primaryLabel, onPressed: onPrimary)),
              if (secondaryLabel != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: PillButton(label: secondaryLabel!, variant: PillVariant.secondary, onPressed: onSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
