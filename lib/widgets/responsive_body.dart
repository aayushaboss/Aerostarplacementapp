import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';

/// Wraps a screen's body so it doesn't just stretch edge-to-edge on a
/// tablet. Below [AppBreakpoints.medium] this is a complete passthrough —
/// every phone size this app has actually been tested at renders exactly
/// as before. Above it, the content is centered and capped at [maxWidth].
///
/// Intended for the whole `Scaffold.body`, not just its scrollable region —
/// screen root structure varies too much across this app (plain ListView,
/// Column+Expanded, Stack+Positioned bottom bar) for "wrap just the
/// scrollable part" to be a mechanical rule. The handful of screens with a
/// genuine full-bleed banner (a colored header, a hero image) wrap only
/// their scrollable content in this instead, leaving the banner outside it.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  // Center everywhere by default, matching every other capped screen in
  // the app. centerLeft is for the rare screen whose content reads as a
  // single linear column (career_dna_landing_screen.dart) rather than an
  // independent page of listings — at a narrow maxWidth relative to a very
  // wide viewport, centering that kind of column left it visibly floating
  // in empty space instead of reading as the page's actual content.
  final Alignment alignment;

  const ResponsiveBody({super.key, required this.child, this.maxWidth = AppBreakpoints.maxContentWidth, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.medium) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
