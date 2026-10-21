import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';

/// Auto-advancing carousel with dot indicators, looping in one direction
/// only. Built on `PageView.builder` with a very large virtual page range
/// (`itemBuilder` resolves every index back to a real card via `i %
/// cards.length`) rather than a small fixed page list — the timer just
/// keeps calling `animateToPage(current + 1)` forever, so every transition,
/// including the wrap from the last real card back to the first, is a
/// genuinely different index producing genuinely real content. There's
/// never a "wrap" case needing a jump/reset, which is what an earlier
/// version of this widget did (a phantom duplicate-of-first page + a hard
/// `jumpToPage(0)` once the animation landed on it) — that trick had a
/// real, confirmed glitch on exactly that transition: `jumpToPage`
/// synchronously re-triggers `onPageChanged` (a second rebuild inside the
/// same transition), and with no `key` on any page, Flutter can't treat
/// the phantom page and the real first page as the same identity across
/// rebuilds, so the hard offset snap wasn't guaranteed to land on a frame
/// boundary matching the eased animation's true rest position.
class AutoCarousel extends StatefulWidget {
  final List<Widget> cards;
  final double height;
  final Duration interval;
  final EdgeInsetsGeometry padding;

  /// Whether to render the page-indicator dots below the cards. Default
  /// true (unchanged behavior for every existing caller). Set false for a
  /// carousel of static, non-interactive cards where the dots are purely
  /// decorative rather than functional (e.g. Courses' NEP/Skill
  /// India/NSDC trust cards) — as opposed to Home's 2-card boost-tip
  /// carousel, where the dots are the only signal a second card exists.
  final bool showDots;

  const AutoCarousel({
    super.key,
    required this.cards,
    required this.height,
    this.interval = const Duration(seconds: 5),
    this.showDots = true,
    // lg (14), not the usual xl (20) section inset — the other 6px lives on
    // each individual page below, not out here. See the per-page Padding
    // in build() for why: splitting one inset into an outer + inner half
    // is the same "shadow-clipping" fix already used elsewhere in this app
    // for an analogous problem — a plain PageView positions adjacent pages
    // flush with zero gap, so with the whole xl inset applied only once,
    // outside the PageView, cards had no separation of their own and
    // visibly merged into each other mid-slide.
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  @override
  State<AutoCarousel> createState() => _AutoCarouselState();
}

class _AutoCarouselState extends State<AutoCarousel> {
  // A large-but-finite starting index, not a literal unbounded start —
  // this is a session-lived widget that will never in practice see more
  // than a few thousand timer ticks, so this multiplier gives vastly more
  // headroom than needed while staying comfortably inside 64-bit int
  // precision with no edge cases to reason about.
  static const _startMultiplier = 10000;

  late final PageController _controller;
  Timer? _timer;
  // Tracked directly rather than read back from `_controller.page` (which
  // is nullable/async-settled) — updated by both the timer's own
  // animateToPage calls and any manual swipe (onPageChanged fires for
  // either), so _advance() always continues forward from wherever the
  // carousel actually is, never from a stale or fallback-guessed index.
  late int _virtualPage;
  int _page = 0;

  int get _count => widget.cards.length;

  @override
  void initState() {
    super.initState();
    _virtualPage = _count * _startMultiplier;
    _controller = PageController(initialPage: _virtualPage);
    if (_count > 1) _timer = Timer.periodic(widget.interval, (_) => _advance());
  }

  Future<void> _advance() async {
    if (!_controller.hasClients) return;
    await _controller.animateToPage(_virtualPage + 1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _onPageChanged(int i) {
    setState(() {
      _virtualPage = i;
      _page = i % _count;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: widget.padding,
          child: SizedBox(
            height: widget.height,
            // A PageView hard-clips to its box, which cut the card shadow flat along the
            // top and bottom edges of the yellow cards. Clipping only the sides (the
            // next page must not show) and letting the shadow paint above and below fixes it.
            child: ClipRect(
              clipper: const _SideClipper(AppShadows.cardBuffer),
              child: PageView.builder(
              clipBehavior: Clip.none,
              controller: _controller,
              // Bounded to _count when there's nothing to loop (0 or 1
              // cards) so this behaves as a plain, non-scrolling single
              // page rather than an unbounded builder with a modulo that
              // would throw on an empty list; unbounded (null) otherwise.
              itemCount: _count > 1 ? null : _count,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => Padding(
                // sm (6) per page — paired with the outer lg (14) above,
                // this restores the usual xl (20) total resting inset
                // while giving each card its own clearance from the page
                // boundary, so a mid-slide transition shows a real ~12px
                // gap between outgoing and incoming cards instead of them
                // touching.
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: widget.cards[i % _count],
              ),
            ),
            ),
          ),
        ),
        if (widget.showDots && _count > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _count,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: i == _page ? AppColors.blue : AppColors.gray200, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Clips to the carousel's width but extends [vertical] pixels above and below,
/// so a card's drop shadow is not cut off at the PageView's edge.
class _SideClipper extends CustomClipper<Rect> {
  final double vertical;
  const _SideClipper(this.vertical);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, -vertical, size.width, size.height + vertical);

  @override
  bool shouldReclip(_SideClipper oldClipper) => oldClipper.vertical != vertical;
}
