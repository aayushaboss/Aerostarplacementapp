import 'package:flutter/material.dart';

/// Mirrors frontend/src/theme.ts `shadow` (RN shadow objects → Flutter BoxShadow).
class AppShadows {
  AppShadows._();

  // Naukri-inspired job-card shadow, scaled down from the original
  // naukri.com mobile audit (0 14px 40px rgba(30,10,58,0.1)) — the original
  // needed 26px of clearance above every card to fade out cleanly, which
  // forced a title-to-carousel gap wider than it should be. Shrunk once
  // already to 0 8px 24px, then shrunk again to 0 4px 12px at the same
  // alpha: still reads as a clear "lifted card" shadow, just noticeably
  // tighter, so the clearance it needs (see [cardBuffer]) shrinks with it —
  // the 24px version needed an asymmetric 16px-top/32px-bottom buffer to
  // avoid a hard-clipped edge in a horizontal card lane; this size needs
  // only 16px on *both* sides, which is what let every section-to-section
  // gap on the home feed collapse back to a single, tighter 16px rhythm
  // instead of ballooning to 32 to stay shadow-safe. Cards get their
  // separation from this alone, no border, which is why every card-style
  // widget switched from Border.all(AppColors.border) to this shadow.
  //
  // Alpha bumped 0x1A -> 0x33 (~10% -> ~20% opacity) after live feedback
  // that cards barely read as elevated against the app's own white page
  // background. Deliberately the only lever touched here — blurRadius/
  // offset stay exactly as they were, so [cardBuffer] (derived from those
  // two) and every carousel-lane file that sizes itself off it need no
  // change at all.
  static const card = [
    BoxShadow(
      color: Color(0x331E0A3A),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const soft = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 5,
    ),
  ];

  static const brand = [
    BoxShadow(
      color: Color(0x66FFC72C),
      offset: Offset(0, 6),
      blurRadius: 14,
    ),
  ];

  /// The same glow under its colour name (a yellow button or badge on a blue surface).
  static const yellow = brand;

  /// Floating overlay shadow (dropdown suggestion panels) — a tighter,
  /// more neutral shadow than [card]'s wide 40px blur, since a dropdown
  /// sits directly against the field it belongs to rather than as its own
  /// separated block.
  static const dropdown = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 6),
      blurRadius: 16,
    ),
  ];

  /// Clearance a horizontally-scrolling card lane needs above/below a card
  /// using [card]'s shadow so a ListView's own edge-clip doesn't cut the
  /// blur off flat — every such lane sizes its SizedBox as
  /// `cardHeight + AppShadows.cardBuffer * 2` and gives its ListView
  /// `padding: EdgeInsets.symmetric(vertical: cardBuffer)` (or the
  /// equivalent per-side `EdgeInsets.fromLTRB` when the lane also needs
  /// different left/right insets).
  ///
  /// [card]'s blur only ever offsets downward, so the true clearance need
  /// is asymmetric: `blurRadius - offsetY` above a card, `blurRadius +
  /// offsetY` below it. With the current `offset: (0, 4)` / `blurRadius:
  /// 12`, that's 8 above and 16 below — both comfortably covered by this
  /// one 16px value (a couple of spare px above never hurts; the failure
  /// mode is only ever *under*-buffering, which clips the fade into a
  /// visible hard edge). A single shared constant only works because this
  /// shadow is small enough for that margin — this was two asymmetric
  /// constants (16/32) before the shadow itself shrank; changing [card]'s
  /// blur/offset again means rechecking whether one value still covers both
  /// sides, and splitting back into two if it no longer does.
  static const double cardBuffer = 16;
}
