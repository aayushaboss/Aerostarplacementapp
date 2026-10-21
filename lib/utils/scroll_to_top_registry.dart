import 'package:flutter/widgets.dart';

/// Lets a tab-root screen register a "scroll to top" callback keyed by its
/// own router branch index, so TabsScaffold can trigger it on a re-tap of
/// the already-active tab without owning that screen's ScrollController
/// directly (branches are built lazily inside an IndexedStack, so
/// TabsScaffold never holds a reference to whichever widget is currently
/// showing for a given branch).
///
/// Each tab-root screen calls [register] in `initState` with its own branch
/// index (see router.dart's StatefulShellRoute branch order) and [unregister]
/// in `dispose`. Registering a new callback for the same index simply
/// replaces the old one, so this stays correct even if a branch's screen
/// widget gets swapped for a different one at runtime (e.g. HomeTabScreen
/// picking SchoolHomeScreen vs CollegeFeedScreen by segment).
class ScrollToTopRegistry {
  ScrollToTopRegistry._();

  static final _callbacks = <int, VoidCallback>{};

  static void register(int branchIndex, VoidCallback cb) => _callbacks[branchIndex] = cb;

  static void unregister(int branchIndex) => _callbacks.remove(branchIndex);

  static void trigger(int branchIndex) => _callbacks[branchIndex]?.call();
}
