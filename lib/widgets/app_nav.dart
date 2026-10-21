import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/user.dart';
import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/initials.dart';
import 'brand.dart';

/// One place the app can go from the sidebar, the navigation rail or the bottom tab bar.
class NavDest {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  /// Set for the entries that are tabs (their position in the tab shell); null for the
  /// "More" entries, which are plain pushed pages.
  final int? branchIndex;

  const NavDest({required this.key, required this.label, required this.icon, required this.activeIcon, required this.route, this.branchIndex});
}

/// The app's navigation items for a student: the tabs (same as the phone's tab bar) and, on a
/// wide window, a "More" group for the pages that live inside Profile on a phone.
class AppNavigation {
  AppNavigation._();

  static List<NavDest> primary(User? user) {
    final school = user?.segment == Segment.school;
    return [
      const NavDest(key: 'home', label: 'Home', icon: Ionicons.home_outline, activeIcon: Ionicons.home, route: '/tabs', branchIndex: 0),
      if (!school) const NavDest(key: 'applications', label: 'Applications', icon: Ionicons.list_outline, activeIcon: Ionicons.list, route: '/tabs/browse', branchIndex: 1),
      if (school) const NavDest(key: 'sessions', label: 'Sessions', icon: Ionicons.calendar_outline, activeIcon: Ionicons.calendar, route: '/tabs/sessions', branchIndex: 2),
      if (!school) const NavDest(key: 'quiz', label: 'Career Quiz', icon: Ionicons.finger_print_outline, activeIcon: Ionicons.finger_print, route: '/tabs/career-dna', branchIndex: 5),
      NavDest(key: 'courses', label: 'Courses', icon: Ionicons.flash_outline, activeIcon: Ionicons.flash, route: school ? '/tabs/browse' : '/tabs/explore', branchIndex: school ? 1 : 3),
      const NavDest(key: 'profile', label: 'Profile', icon: Ionicons.person_outline, activeIcon: Ionicons.person, route: '/tabs/profile', branchIndex: 4),
    ];
  }

  static List<NavDest> secondary(User? user) {
    final school = user?.segment == Segment.school;
    return [
      if (!school) const NavDest(key: 'saved', label: 'Saved', icon: Ionicons.bookmark_outline, activeIcon: Ionicons.bookmark, route: '/saved'),
      const NavDest(key: 'bookings', label: 'Bookings', icon: Ionicons.calendar_outline, activeIcon: Ionicons.calendar, route: '/tabs/sessions'),
      const NavDest(key: 'notifications', label: 'Notifications', icon: Ionicons.notifications_outline, activeIcon: Ionicons.notifications, route: '/notifications'),
      const NavDest(key: 'support', label: 'Support & Help', icon: Ionicons.help_circle_outline, activeIcon: Ionicons.help_circle, route: '/support'),
    ];
  }

  /// Which item is highlighted for a page. Detail pages light up the section they belong to, so
  /// the student always sees where they are.
  static String activeKeyFor(String location, User? user) {
    final school = user?.segment == Segment.school;
    final path = location.split('?').first;
    if (path == '/tabs') return 'home';
    if (path.startsWith('/tabs/browse')) return school ? 'courses' : 'applications';
    if (path.startsWith('/tabs/sessions')) return school ? 'sessions' : 'bookings';
    if (path.startsWith('/tabs/explore')) return 'courses';
    if (path.startsWith('/tabs/career-dna')) return 'quiz';
    if (path.startsWith('/tabs/profile')) return 'profile';
    if (path.startsWith('/saved')) return 'saved';
    if (path.startsWith('/notifications')) return 'notifications';
    if (path.startsWith('/support')) return 'support';
    if (path.startsWith('/application')) return 'applications';
    if (path.startsWith('/course')) return 'courses';
    if (path.startsWith('/college/career-dna')) return 'quiz';
    if (path.startsWith('/profile-edit') || path.startsWith('/college/resume') || path.startsWith('/search-appearances') || path.startsWith('/recruiter-actions')) return 'profile';
    return 'home';
  }

  static String segmentLabel(User? user) {
    switch (user?.segment) {
      case Segment.school:
        return 'School Student';
      case Segment.ug:
        return 'Undergraduate';
      case Segment.pg:
        return 'Postgraduate';
      case Segment.working:
        return 'Working';
      case null:
        return 'Student';
    }
  }
}

/// The 248px sidebar shown on an expanded window.
class AppSidebar extends StatelessWidget {
  final User? user;
  final String activeKey;
  final bool unreadNotifications;
  final ValueChanged<NavDest> onSelect;

  const AppSidebar({super.key, required this.user, required this.activeKey, required this.unreadNotifications, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppBreakpoints.sidebarWidth,
      decoration: const BoxDecoration(color: AppColors.white, border: Border(right: BorderSide(color: AppColors.border, width: 1))),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md - 4),
            child: Align(alignment: Alignment.centerLeft, child: Wordmark(size: 22)),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final d in AppNavigation.primary(user)) ...[
            _SidebarItem(dest: d, active: d.key == activeKey, height: 44, iconSize: 20, fontSize: 14, onTap: () => onSelect(d)),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md - 4, AppSpacing.xl, 0, AppSpacing.sm),
            child: Text('MORE', style: TextStyle(fontFamily: kFontFamily, fontSize: 11, fontWeight: AppFontWeight.medium, letterSpacing: 1.2, color: AppColors.gray500)),
          ),
          for (final d in AppNavigation.secondary(user)) ...[
            _SidebarItem(
              dest: d,
              active: d.key == activeKey,
              height: 40,
              iconSize: 18,
              fontSize: 13,
              dot: d.key == 'notifications' && unreadNotifications,
              onTap: () => onSelect(d),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Spacer(),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, 0),
            child: Row(
              children: [
                _Avatar(name: user?.name, photoUrl: user?.photoUrl, size: 36, fontSize: 13),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Student', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                      Text(AppNavigation.segmentLabel(user), style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final NavDest dest;
  final bool active;
  final double height;
  final double iconSize;
  final double fontSize;
  final bool dot;
  final VoidCallback onTap;

  const _SidebarItem({required this.dest, required this.active, required this.height, required this.iconSize, required this.fontSize, this.dot = false, required this.onTap});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final color = active ? AppColors.blue : AppColors.gray500;
    return Semantics(
      button: true,
      selected: active,
      label: widget.dest.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4),
            decoration: BoxDecoration(
              // Active or hovered rows are the neutral light fill: no yellow in the navigation.
              color: active ? AppColors.blueA10 : (_hover ? AppColors.offWhite : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(active ? widget.dest.activeIcon : widget.dest.icon, size: widget.iconSize, color: color),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(
                  child: Text(
                    widget.dest.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontSize: widget.fontSize, color: color, fontWeight: active ? AppFontWeight.semibold : AppFontWeight.medium),
                  ),
                ),
                if (widget.dot) const _UnreadDot(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 80px navigation rail shown on a medium window.
class AppNavRail extends StatelessWidget {
  final User? user;
  final String activeKey;
  final bool unreadNotifications;
  final ValueChanged<NavDest> onSelect;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const AppNavRail({
    super.key,
    required this.user,
    required this.activeKey,
    required this.unreadNotifications,
    required this.onSelect,
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppBreakpoints.railWidth,
      decoration: const BoxDecoration(color: AppColors.white, border: Border(right: BorderSide(color: AppColors.border, width: 1))),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const BrandMark(size: 28),
          const SizedBox(height: AppSpacing.xl),
          for (final d in AppNavigation.primary(user)) ...[
            _RailItem(dest: d, active: d.key == activeKey, onTap: () => onSelect(d)),
            const SizedBox(height: AppSpacing.md),
          ],
          const Spacer(),
          Semantics(
            button: true,
            label: 'Notifications',
            child: GestureDetector(
              onTap: onNotifications,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                    child: const Icon(Ionicons.notifications_outline, size: 20, color: AppColors.blue),
                  ),
                  if (unreadNotifications) const Positioned(top: 9, right: 10, child: _UnreadDot(withRing: true)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(onTap: onProfile, child: _Avatar(name: user?.name, photoUrl: user?.photoUrl, size: 40, fontSize: 14)),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final NavDest dest;
  final bool active;
  final VoidCallback onTap;
  const _RailItem({required this.dest, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blue : AppColors.gray500;
    return Semantics(
      button: true,
      selected: active,
      label: dest.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: AppBreakpoints.railWidth,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: active ? AppColors.blueA10 : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Icon(active ? dest.activeIcon : dest.icon, size: 22, color: color),
                ),
                const SizedBox(height: AppSpacing.xs),
                // One line, scaled down if a long label ("Applications") would not fit the 80px rail.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      dest.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppTextStyles.label.copyWith(fontSize: 11, height: 1.2, color: color, fontWeight: active ? AppFontWeight.semibold : AppFontWeight.medium),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final double size;
  final double fontSize;
  const _Avatar({required this.name, required this.photoUrl, required this.size, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.blue,
        alignment: Alignment.center,
        child: photoUrl != null
            ? Image.network(photoUrl!, width: size, height: size, fit: BoxFit.cover)
            : Text(initialsFor(name), style: AppTextStyles.body.copyWith(color: AppColors.white, fontSize: fontSize, fontWeight: AppFontWeight.semibold)),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  final bool withRing;
  const _UnreadDot({this.withRing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        border: withRing ? Border.all(color: AppColors.offWhite, width: 1.5) : null,
      ),
    );
  }
}
