import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// The page scaffold for a tablet or desktop window: a header (optional back link, title,
/// subtitle and actions on the right), then the body, both in one centred column with the
/// window's gutter. Use it for every tab and pushed page when [AppBreakpoints.isWide]; phones keep
/// their own layout.
///
/// Titles are left aligned (the centred title bar is phone-only).
class AppPage extends StatelessWidget {
  /// "Back to Home": a back link above the title. Null on a tab's root page.
  final String? backLabel;

  /// Where the back link goes when there is nothing to go back to (a deep link).
  final String backFallback;

  final String? title;
  final String? subtitle;
  final bool largeTitle;

  /// Buttons and controls on the right of the title.
  final List<Widget> actions;

  /// Replaces the title block (for a header like the profile strip).
  final Widget? header;

  final Widget body;

  /// Wrap [body] in a vertical scroll view. Turn off when the body manages its own scrolling
  /// (master-detail panes, chat).
  final bool scroll;

  final ScrollController? controller;

  /// Overrides the default content width cap.
  final double? maxWidth;

  /// Space under the body (the content scrolls under it).
  final double bottomPadding;

  /// Draw a hairline under the header (list pages with their own panes).
  final bool headerDivider;

  const AppPage({
    super.key,
    this.backLabel,
    this.backFallback = '/tabs',
    this.title,
    this.subtitle,
    this.largeTitle = false,
    this.actions = const [],
    this.header,
    required this.body,
    this.scroll = true,
    this.controller,
    this.maxWidth,
    this.bottomPadding = AppSpacing.xl,
    this.headerDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final gutter = AppBreakpoints.gutter(context);
    final cap = maxWidth ?? AppBreakpoints.maxContentFor(context);

    Widget column(Widget child, {EdgeInsets padding = EdgeInsets.zero}) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cap),
            child: Padding(padding: padding.add(EdgeInsets.symmetric(horizontal: gutter)), child: child),
          ),
        );

    final hasHeader = header != null || title != null || backLabel != null;
    final headerBlock = !hasHeader
        ? null
        : column(
            header ??
                PageHeader(
                  backLabel: backLabel,
                  backFallback: backFallback,
                  title: title,
                  subtitle: subtitle,
                  largeTitle: largeTitle,
                  actions: actions,
                ),
            padding: const EdgeInsets.only(top: AppSpacing.xl),
          );

    final bodyColumn = column(body, padding: EdgeInsets.only(top: hasHeader ? AppSpacing.lg : AppSpacing.xl, bottom: bottomPadding));

    return Material(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerBlock != null) headerBlock,
          if (headerDivider)
            Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: Container(height: 1, color: AppColors.border))
          else
            const SizedBox.shrink(),
          Expanded(
            child: scroll
                ? SingleChildScrollView(
                    controller: controller,
                    child: bodyColumn,
                  )
                : bodyColumn,
          ),
        ],
      ),
    );
  }
}

/// Back link, title, subtitle and actions.
class PageHeader extends StatelessWidget {
  final String? backLabel;
  final String backFallback;
  final String? title;
  final String? subtitle;
  final bool largeTitle;
  final List<Widget> actions;

  const PageHeader({super.key, this.backLabel, this.backFallback = '/tabs', this.title, this.subtitle, this.largeTitle = false, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (backLabel != null) PageBackLink(label: backLabel!, fallback: backFallback),
        if (title != null)
          Padding(
            padding: EdgeInsets.only(top: backLabel != null ? AppSpacing.sm : 0),
            child: Text(title!, style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: largeTitle ? 26 : 22)),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14)),
          ),
      ],
    );
    if (actions.isEmpty) return SizedBox(width: double.infinity, child: titleBlock);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: AppSpacing.md),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md - 4),
          actions[i],
        ],
      ],
    );
  }
}

/// "← Back to Applications": pops if it can, else goes to [fallback].
class PageBackLink extends StatelessWidget {
  final String label;
  final String fallback;
  const PageBackLink({super.key, required this.label, this.fallback = '/tabs'});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back to $label',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.canPop() ? context.pop() : context.go(fallback),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Ionicons.arrow_back, size: 14, color: AppColors.ink),
                const SizedBox(width: AppSpacing.xs),
                Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.semibold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A white card lifted off the page by the shared card shadow. Cards are either shadowed or
/// outlined, never both, and a gray [TintCard] has no shadow at all (a blurred shadow around a gray
/// fill makes its edge look fuzzy).
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool selected;
  final VoidCallback? onTap;
  final bool lifted;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.selected = false,
    this.onTap,
    this.lifted = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        // The 2px border is always there (transparent when not selected) so selecting a card never
        // moves its content.
        border: selected ? Border.all(color: AppColors.blue, width: 2) : null,
        boxShadow: lifted ? AppShadows.card : AppShadows.soft,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card));
  }
}

/// A light gray card with a crisp edge: no shadow, no border.
class TintCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  const TintCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.md), this.radius = AppRadius.lg, this.color = AppColors.blueA10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

/// Lays [children] out in a grid of [columns] equal columns, each row as tall as its tallest card
/// (so cards of different content heights line up). Cards come from the grid, never a fixed width.
class AppGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final List<Widget> children;

  const AppGrid({super.key, required this.columns, required this.children, this.gap = AppSpacing.lg});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: gap),
                Expanded(child: c < slice.length ? slice[c] : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) rows.add(SizedBox(height: gap));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// "Marketing (300)   View all →" above a grid or list.
class SectionHeading extends StatelessWidget {
  final String title;
  final int? count;
  final VoidCallback? onViewAll;
  final EdgeInsetsGeometry padding;

  const SectionHeading({super.key, required this.title, this.count, this.onViewAll, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // The title takes the free space (Expanded, not Flexible + Spacer, which would split it
          // and leave "View all" floating in the middle).
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h3.copyWith(color: AppColors.ink))),
                if (count != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text('($count)', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onViewAll,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View all', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Ionicons.arrow_forward, size: 14, color: AppColors.blue),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A main column with a pinned card on the right (320px): job detail, booking summary, save
/// changes. The main column scrolls on its own and the side card stays put, so use it inside an
/// [AppPage] with scroll: false.
class TwoPane extends StatelessWidget {
  final Widget main;
  final Widget side;
  final double sideWidth;
  final double gap;

  const TwoPane({super.key, required this.main, required this.side, this.sideWidth = 320, this.gap = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: AppSpacing.xl), child: main)),
        SizedBox(width: gap),
        SizedBox(width: sideWidth, child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: AppSpacing.xl), child: side)),
      ],
    );
  }
}
