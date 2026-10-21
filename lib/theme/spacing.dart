/// Strict 8pt spacing grid — every value is a multiple of the 8px base
/// unit (the 2026 standard for mobile/web UI). This app's scale was
/// previously tightened off-grid (xs4/sm6/md10/lg14/xl20/xxl26/xxxl40) for
/// density reasons; per direct instruction it's back on a true 8pt grid
/// now. `xs` is the one exception (4 = half-step), kept for hairline gaps
/// (e.g. the 2-4px under a label) that a jump straight to 8 would make
/// too loose.
///
/// Rough vertical-rhythm convention used across this app: `sm` between
/// closely-related items (a title and its subtitle), `md` between
/// distinct elements within one block (an icon and its label), `lg`/`xl`
/// between sections, `xxl`/`xxxl` for a screen's outermost/hero spacing.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Mirrors frontend/src/theme.ts `radius`.
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}
