import 'package:flutter/widgets.dart';

/// Material 3 window size classes. Compact is the phone layout and is never
/// touched by the tablet/desktop work; medium and expanded are the two-pane
/// app: a navigation rail (medium) or a sidebar (expanded) next to the content.
///
/// | Class    | Width    | Navigation          | Gutter | Content max | Card grid        |
/// |----------|----------|---------------------|--------|-------------|------------------|
/// | compact  | < 600    | bottom tab bar      | 32     | none        | 1 column         |
/// | medium   | 600-839  | 80px navigation rail| 32     | 760         | 2 columns        |
/// | expanded | >= 840   | 248px sidebar       | 40     | 1200        | 3 (4 from 1360)  |
enum AppBreakpoint { compact, medium, expanded }

class AppBreakpoints {
  AppBreakpoints._();

  static const double medium = 600;
  static const double expanded = 840;

  /// Widest the content column grows on an expanded window.
  static const double maxContent = 1200;

  /// Widest the content column grows on a medium window.
  static const double maxContentMedium = 760;

  /// Forms, articles and quiz questions: a comfortable reading line.
  static const double readingWidth = 680;

  /// Width of the navigation rail (medium) and the sidebar (expanded).
  static const double railWidth = 80;
  static const double sidebarWidth = 248;

  /// Cap for the single-column focus screens on a phone-sized window.
  static const double maxContentWidth = 520;

  static AppBreakpoint of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);

  static AppBreakpoint forWidth(double width) {
    if (width >= expanded) return AppBreakpoint.expanded;
    if (width >= medium) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }

  /// Medium or expanded: the window shows the rail or sidebar.
  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= medium;

  static bool isExpanded(BuildContext context) => MediaQuery.sizeOf(context).width >= expanded;

  /// The content pane is the window minus the rail or sidebar, so a screen
  /// lays out against this rather than the window width.
  static double contentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= expanded) return w - sidebarWidth;
    if (w >= medium) return w - railWidth;
    return w;
  }

  /// Side gutter of the content column.
  static double gutter(BuildContext context) => isExpanded(context) ? 40 : 32;

  /// Widest the content column grows at this window size.
  static double maxContentFor(BuildContext context) => isExpanded(context) ? maxContent : maxContentMedium;

  /// How many cards fit across a grid: 2 on medium, 3 on expanded, 4 from a
  /// 1360px window.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1360) return 4;
    if (w >= expanded) return 3;
    if (w >= medium) return 2;
    return 1;
  }
}
