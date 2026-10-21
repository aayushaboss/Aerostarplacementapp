import 'package:flutter/material.dart';

/// Aerostar Edge design tokens — brand match to aerostaredge.com.
///
/// Two brand colors, each with one job:
///  * [blue] is the interactive and informational accent: selected chips, links and "View all →",
///    the active tab underline, focus rings, tags, progress, saved bookmarks, secondary buttons,
///    and the solid hero surfaces that carry a feature moment (white text on them).
///  * [yellow] (also exposed as [brand]) is the primary call to action: the one filled button per
///    screen (ink label on it), plus small highlights on blue hero surfaces and success-check
///    circles. It is a light color, so it is never text on white.
///
/// Pages are white; cards are white with a soft shadow or an [offWhite] fill.
class AppColors {
  AppColors._();

  // brand
  static const blue = Color(0xFF0A2FFF);
  static const blueDark = Color(0xFF0722B8);
  static const blueDeep = Color(0xFF061A8C);
  static const yellow = Color(0xFFFFC72C);
  static const yellowDark = Color(0xFFE6B316);

  /// The call-to-action fill (yellow) and its pressed state.
  static const brand = yellow;
  static const brandPressed = yellowDark;
  // Deep neutral for dark surfaces that stay on-palette (skill story backgrounds).
  static const brandDeep = blueDeep;

  // surfaces
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF5F5F7);
  static const gray100 = Color(0xFFE5E5EA);
  static const gray200 = Color(0xFFD1D1D6);
  static const gray400 = Color(0xFFA1A1AA);
  static const gray500 = Color(0xFF71717A);
  static const ink = Color(0xFF1C1C1E);

  // Text/icon color to use on top of a [brand] (yellow) fill.
  static const onBrand = ink;

  // status
  // Material Design green 500: a widely recognized "success" green.
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);
  static const info = blue;
  // A visible keyboard-focus outline uses the app's one interactive accent.
  static const focusRing = blue;
  // Darker variants for small text sat on that same color's own ~15% tint
  // — the plain success/warning values above read fine as icon fills, but
  // as StatusBadge's foreground text-on-tint they fell under WCAG AA
  // (~2.2-2.6:1). These pass comfortably at the same 12px size.
  static const successDark = Color(0xFF2E7D32);
  static const warningDark = Color(0xFFB25900);
  // Interview's own accent: distinct from Applied's blue.
  static const violet = Color(0xFF7C4DFF);
  static const violetA15 = Color(0x267C4DFF);

  static const border = Color(0xFFE5E5EA);

  // translucent
  static const whiteA10 = Color(0x1AFFFFFF);
  static const whiteA15 = Color(0x26FFFFFF);
  static const whiteA20 = Color(0x33FFFFFF);
  static const whiteA70 = Color(0xB3FFFFFF);
  // Secondary text/captions on a [brand] fill.
  static const inkA70 = Color(0xB31C1C1E);
  static const blueA10 = Color(0x1A0A2FFF);
  // Course cards' accent — deliberately not blue, so a course card reads as visually distinct
  // from a job card at a glance.
  static const yellowA15 = Color(0x26FFC72C);
  static const successA10 = Color(0x1A4CAF50);
  static const warningA15 = Color(0x24FF9500);
  static const errorA10 = Color(0x1FFF3B30);
  static const gray500A15 = Color(0x2471717A);
}
