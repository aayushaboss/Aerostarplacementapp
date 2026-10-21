import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../mockData/mock_notifications.dart';
import '../screens/shared/notifications_screen.dart' show openNotifications;
import '../state/app_state.dart';
import '../theme/breakpoints.dart';
import 'app_nav.dart';

/// Puts the navigation next to a screen on a wide window: a rail on a medium one, a sidebar on an
/// expanded one. On a phone-sized window it is a plain pass-through, so the phone layout is never
/// touched.
class AppShellFrame extends StatelessWidget {
  final Widget child;
  final String activeKey;
  final ValueChanged<NavDest> onSelect;

  const AppShellFrame({super.key, required this.child, required this.activeKey, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.medium) return child;
    final appState = context.watch<AppState>();
    final user = appState.user;
    final unread = appState.hasUnreadNotifications(mockNotifications.map((n) => n.id).toList());
    final nav = width >= AppBreakpoints.expanded
        ? AppSidebar(user: user, activeKey: activeKey, unreadNotifications: unread, onSelect: (d) => d.key == 'notifications' ? openNotifications(context) : onSelect(d))
        : AppNavRail(
            user: user,
            activeKey: activeKey,
            unreadNotifications: unread,
            onSelect: onSelect,
            onNotifications: () => openNotifications(context),
            onProfile: () => context.go('/tabs/profile'),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [nav, Expanded(child: child)],
    );
  }
}

/// Wraps every pushed page (job detail, application detail, booking, notifications...) so the
/// navigation stays visible on a wide window. On a phone these pages still cover the whole screen.
class PushedShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;
  const PushedShell({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AppShellFrame(
        activeKey: AppNavigation.activeKeyFor(state.uri.toString(), user),
        onSelect: (d) => context.go(d.route),
        child: child,
      ),
    );
  }
}
