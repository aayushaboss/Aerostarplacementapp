import 'package:flutter/material.dart';

/// Dismisses any showing SnackBar the moment a new route is pushed, an
/// existing one is replaced, or the user pops back — MaterialApp.router
/// only ever creates ONE ScaffoldMessenger for the whole app, so without
/// this a SnackBar shown on one screen (e.g. "Removed X — Undo" on the
/// Applications tab) stays on screen through any navigation, including a
/// full logout, until its own duration elapses.
class SnackBarDismissObserver extends NavigatorObserver {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  SnackBarDismissObserver(this.scaffoldMessengerKey);

  void _clear() => scaffoldMessengerKey.currentState?.clearSnackBars();

  @override
  void didPush(Route route, Route? previousRoute) => _clear();

  @override
  void didPop(Route route, Route? previousRoute) => _clear();

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _clear();
}
