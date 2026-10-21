import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/initials.dart';

/// The 72px bar across the top of Home on an expanded window: the search field (and the filter
/// button), then the bell and the avatar on the right.
class HomeTopBar extends StatelessWidget {
  final Widget search;
  final VoidCallback? onFilter;
  final bool filtering;
  final bool unread;
  final String? name;
  final String? photoUrl;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;

  const HomeTopBar({super.key, required this.search, this.onFilter, this.filtering = false, this.unread = false, this.name, this.photoUrl, this.onBell, this.onAvatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: AppBreakpoints.gutter(context)),
      decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
      child: Row(
        children: [
          Flexible(flex: 0, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480, minWidth: 240), child: search)),
          if (onFilter != null) ...[
            const SizedBox(width: AppSpacing.md - 4),
            HomeCircleButton(icon: filtering ? Ionicons.options : Ionicons.options_outline, size: 44, label: 'Filter', dot: filtering, dotColor: AppColors.error, onTap: onFilter),
          ],
          const Spacer(),
          HomeCircleButton(icon: Ionicons.notifications_outline, size: 40, label: 'Notifications', dot: unread, dotColor: AppColors.error, onTap: onBell),
          const SizedBox(width: AppSpacing.md - 4),
          Semantics(
            button: true,
            label: 'Profile',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAvatar,
                child: ClipOval(
                  child: Container(
                    width: 40,
                    height: 40,
                    color: AppColors.blue,
                    alignment: Alignment.center,
                    child: photoUrl != null
                        ? Image.network(photoUrl!, width: 40, height: 40, fit: BoxFit.cover)
                        : Text(initialsFor(name), style: AppTextStyles.body.copyWith(color: AppColors.white, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round light-gray icon button with an optional status dot.
class HomeCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final String label;
  final bool dot;
  final Color dotColor;
  final VoidCallback? onTap;

  const HomeCircleButton({super.key, required this.icon, required this.size, required this.label, this.dot = false, this.dotColor = AppColors.error, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                child: Icon(icon, size: size >= 44 ? 20 : 22, color: AppColors.blue),
              ),
              if (dot)
                Positioned(
                  top: size * 0.22,
                  right: size * 0.25,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: Border.all(color: AppColors.offWhite, width: 1.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
