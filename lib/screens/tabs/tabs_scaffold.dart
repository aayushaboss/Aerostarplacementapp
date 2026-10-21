import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../college/college_feed_screen.dart';
import '../school/courses_explore_screen.dart';
import '../school/school_home_screen.dart';
import '../shared/applications_tracker_screen.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/accessible_tap_target.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/responsive_body.dart';

/// One bottom-tab-bar entry — used only by [TabsScaffold] now that there's
/// no separate top-nav-bar chrome to also share it with.
class TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int branchIndex;
  const TabItem({required this.icon, required this.activeIcon, required this.label, required this.branchIndex});
}

/// Home tab body: SchoolHome for school segment, CollegeFeed otherwise.
/// Mirrors frontend/app/(tabs)/index.tsx.
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSchool = context.watch<AppState>().user?.segment == Segment.school;
    return isSchool ? const SchoolHomeScreen() : const CollegeFeedScreen();
  }
}

/// Browse tab body: CoursesExplore for school segment, ApplicationsTracker
/// otherwise. Mirrors frontend/app/(tabs)/browse.tsx.
class BrowseTabScreen extends StatelessWidget {
  const BrowseTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSchool = context.watch<AppState>().user?.segment == Segment.school;
    return isSchool ? const CoursesExploreScreen() : const ApplicationsTrackerScreen();
  }
}

/// Bottom tab bar shell — the app's only navigation chrome, at every width
/// (mobile+tablet only; there is no separate top nav bar or sidebar).
/// Mirrors frontend/app/(tabs)/_layout.tsx. The "Courses" tab shows course
/// discovery for both segments — branch index 3 (labeled Explore internally
/// in the router) for college, branch index 1 (BrowseTabScreen's own
/// CoursesExploreScreen) for school, who otherwise have no separate
/// Applications tab to occupy that slot. Saved opportunities moved off the
/// tab bar entirely into a Profile row now that this slot is Courses.
///
/// Every other screen in the app (job/application detail, resume builder,
/// the filter screen, booking, etc.) is a top-level pushed route that
/// replaces the whole shell today, so it stays full-screen with no tab bar
/// there too.
class TabsScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const TabsScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSchool = appState.user?.segment == Segment.school;

    // Tab-bar visual order is independent of each route's branchIndex, so
    // reordering here never needs router changes — just where each item
    // appears in this list. Order: Home, Applications (college-only) /
    // Sessions (school-only), Courses, Profile.
    //
    // College has no Bookings item — branch 2 (Sessions screen) is
    // reachable from Profile's "Bookings" row and Home's tappable Upcoming
    // Session card, which is enough for what's a secondary JTBD there.
    // School gets Sessions as a bottom-tab item in its own right — counseling
    // is co-equal with aptitude/courses as school's top job-to-be-done, so it
    // belongs in the main menu rather than tucked away in Profile.
    final items = <TabItem>[
      const TabItem(icon: Ionicons.home_outline, activeIcon: Ionicons.home, label: 'Home', branchIndex: 0),
      if (!isSchool) const TabItem(icon: Ionicons.list_outline, activeIcon: Ionicons.list, label: 'Applications', branchIndex: 1),
      if (isSchool) const TabItem(icon: Ionicons.calendar_outline, activeIcon: Ionicons.calendar, label: 'Sessions', branchIndex: 2),
      // The flagship "Career Quiz" feature (Round AA, internally still
      // called "Career DNA" in file/class names — renamed only in
      // user-facing copy after live feedback that the name needed no
      // explanation) — college only, its own branch appended at index 5
      // in router.dart so no existing branch's index shifts.
      if (!isSchool) const TabItem(icon: Ionicons.finger_print_outline, activeIcon: Ionicons.finger_print, label: 'Career Quiz', branchIndex: 5),
      TabItem(icon: Ionicons.flash_outline, activeIcon: Ionicons.flash, label: 'Courses', branchIndex: isSchool ? 1 : 3),
      const TabItem(icon: Ionicons.person_outline, activeIcon: Ionicons.person, label: 'Profile', branchIndex: 4),
    ];

    void handleTap(TabItem item) {
      HapticFeedback.selectionClick();
      // IndexedStack preserves each branch's state across switches (that's
      // the point), so a snackbar shown on one tab would otherwise still be
      // sitting there after switching away — the NavigatorObserver on
      // GoRouter doesn't fire for this since it's a visibility change, not
      // a push/pop.
      ScaffoldMessenger.of(context).clearSnackBars();
      final wasAlreadyActive = item.branchIndex == shell.currentIndex;
      shell.goBranch(item.branchIndex, initialLocation: wasAlreadyActive);
      // Re-tapping the tab you're already on pops its nested Navigator back
      // to its root route (that's what initialLocation does above) but
      // doesn't touch scroll position on its own — that screen's own
      // ScrollController does the rest.
      if (wasAlreadyActive) ScrollToTopRegistry.trigger(item.branchIndex);
    }

    // On a medium or expanded window the bottom bar gives way to a navigation rail or a sidebar.
    if (AppBreakpoints.isWide(context)) {
      final branch = shell.currentIndex;
      final activeKey = switch (branch) {
        0 => 'home',
        1 => isSchool ? 'courses' : 'applications',
        2 => isSchool ? 'sessions' : 'bookings',
        3 => 'courses',
        4 => 'profile',
        _ => 'quiz',
      };
      void select(NavDest d) {
        final target = d.branchIndex;
        if (target == null) {
          context.go(d.route);
          return;
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        final wasAlreadyActive = target == shell.currentIndex;
        shell.goBranch(target, initialLocation: wasAlreadyActive);
        if (wasAlreadyActive) ScrollToTopRegistry.trigger(target);
      }

      return Scaffold(
        backgroundColor: AppColors.white,
        body: AppShellFrame(activeKey: activeKey, onSelect: select, child: shell),
      );
    }

    // College's bar has 5 items (school's 4) since Career Quiz was added —
    // shrinking icon/label size only when there are actually 5 items keeps
    // school's own bar exactly as it always was, rather than shrinking
    // both segments' bars for a crowding problem only one of them has.
    final iconSize = items.length > 4 ? 21.0 : 24.0;
    final labelFontSize = items.length > 4 ? 9.5 : 11.0;

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              // Caps and centers just the tab row on tablet — otherwise 4
              // items stretched across ~768-1024px each get a lot of empty
              // space around a small centered icon+label, reading as sparse
              // rather than a deliberate wide layout. 720, matching
              // Applications' own maxWidth (needed there for its 2-column
              // grid) rather than the 520 default every other tab uses —
              // the bar sitting under a screen's max possible content width
              // avoids it visibly narrowing/widening every time the active
              // tab changes.
              child: ResponsiveBody(maxWidth: 720, child: Row(
                children: items.map((item) {
                  final active = shell.currentIndex == item.branchIndex;
                  return Expanded(
                    child: AccessibleTapTarget(
                      label: item.label,
                      selected: active,
                      onTap: () => handleTap(item),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // No colour fill: the active tab is shown by the filled icon
                          // variant plus a blue, semibold label (inactive = gray500).
                          Icon(active ? item.activeIcon : item.icon, size: iconSize, color: active ? AppColors.blue : AppColors.gray500),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.label,
                            style: AppTextStyles.label.copyWith(
                              fontSize: labelFontSize,
                              color: active ? AppColors.blue : AppColors.gray500,
                              fontWeight: active ? AppFontWeight.semibold : AppFontWeight.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )),
            ),
          ),
        ),
      ),
    );
  }
}
