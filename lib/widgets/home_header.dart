import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/initials.dart';

/// Mirrors frontend/src/components/HomeHeader.tsx.
/// Pure presentational — navigation/auth data comes in via params + callbacks,
/// not pulled from router/context directly.
class HomeHeader extends StatelessWidget {
  final String? name;
  final String? subtitle;
  final bool unread;
  final String? photoUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onBellTap;

  const HomeHeader({
    super.key,
    this.name,
    this.subtitle,
    this.unread = true,
    this.photoUrl,
    this.onAvatarTap,
    this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    // Desktop sits directly under TopNavBar's own 64px bar with no notch
    // inset to lean on (topInset is 0 on web) — without this the greeting
    // row butts straight up against the nav bar's bottom border.
    final isTablet = AppBreakpoints.isWide(context);
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(
        top: topInset + AppSpacing.md + (isTablet ? AppSpacing.xl : 0),
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        // Tightened from xl (32) — this header sits directly above the
        // search bar row on both college_feed_screen.dart and
        // school_home_screen.dart, and the two stacked side by side at 32
        // each read as a lot of dead space above the fold. md keeps clear
        // separation without the extra gap.
        bottom: AppSpacing.md,
      ),
      // A flat Row, not two nested ones — the greeting block used to be its
      // own Row sized to its own intrinsic (unbounded) text width, sitting
      // next to the icon Row inside an outer `spaceBetween`. Neither side
      // was ever told to shrink, so on a narrow-enough phone the greeting
      // text alone could exceed the space left after the avatar, and
      // `spaceBetween` pushed the entire icon cluster (search/filter/bell)
      // past the right edge of the screen instead of visibly overflowing —
      // they just silently weren't there. Wrapping the greeting text in
      // Expanded (with an ellipsis) makes it the one flexible element:
      // avatar and icons keep their fixed size and stay on-screen always,
      // and a long name truncates instead of displacing them.
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Profile',
            child: GestureDetector(
              onTap: onAvatarTap,
              child: ClipOval(
                child: Container(
                  width: 44,
                  height: 44,
                  color: AppColors.blue,
                  alignment: Alignment.center,
                  child: photoUrl != null
                      ? Image.network(photoUrl!, width: 44, height: 44, fit: BoxFit.cover)
                      : Text(
                          initialsFor(name),
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: AppFontWeight.semibold,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle ?? 'Welcome back',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.gray500,
                    fontSize: 12,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
                Text(
                  name ?? 'Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Bell only — search and filter moved onto the feed itself as a
          // pinned bar row below this header (see college_feed_screen.dart).
          Semantics(
              button: true,
              label: 'Notifications',
              child: GestureDetector(
                onTap: onBellTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(child: Icon(Ionicons.notifications_outline, size: 22, color: AppColors.ink)),
                      if (unread)
                        Positioned(
                          top: 9,
                          right: 10,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.offWhite, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
