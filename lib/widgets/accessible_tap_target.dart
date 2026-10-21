import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';

/// Wraps an existing tappable widget with a screen-reader label and a
/// visible keyboard-focus outline, without changing its own visuals or
/// hit-testing otherwise. Bootstraps accessibility on the app's
/// highest-traffic tap targets (the bottom tab bar, job/course card taps,
/// primary Profile rows) — not a new interaction pattern, just Focus (same
/// idiom pill_input.dart already uses for its own focus state) plus
/// Semantics (same idiom home_header.dart's icon buttons already use)
/// composed into one reusable wrapper instead of duplicated at each site.
///
/// Deliberately not a general-purpose replacement for every GestureDetector
/// in the app — see Round V's plan for the ~115 call sites this
/// intentionally leaves untouched this round.
class AccessibleTapTarget extends StatefulWidget {
  final String label;
  final bool? selected;
  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  const AccessibleTapTarget({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.selected,
    this.borderRadius,
  });

  @override
  State<AccessibleTapTarget> createState() => _AccessibleTapTargetState();
}

class _AccessibleTapTargetState extends State<AccessibleTapTarget> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        onShowFocusHighlight: (has) => setState(() => _focused = has),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()},
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            decoration: _focused
                ? BoxDecoration(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
                    border: Border.all(color: AppColors.focusRing, width: 2),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
