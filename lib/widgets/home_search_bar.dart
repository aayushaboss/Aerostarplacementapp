import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mockData/mock_opportunities.dart';
import '../mockData/mock_profile_options.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/search_match.dart';

const _recentSearchesKey = 'recent_opportunity_searches';
const _maxRecentSearches = 5;

String _opportunityRoute(String q) => '/opportunities?q=${Uri.encodeQueryComponent(q)}';

/// Single pinned search bar for the college Home feed — replaces the old
/// dedicated `/search` screen. Focus it and a dropdown opens: recent
/// searches (or, first time, a few starter suggestions), then typed-match
/// suggestions while typing. Picking one (or pressing enter) opens
/// `/opportunities` filtered to that query.
///
/// Self-contained fixed-height field (not built on PillInput) so it drops
/// cleanly into a Row/Expanded on the feed without an unbounded-height
/// layout.
///
/// Also the search experience for Courses: the defaults are the jobs search;
/// Courses passes its own hint / history key / suggestion terms / starter
/// chips / destination route, so both tabs behave identically (type, then
/// suggestions, then pick one or press the tick, then a results screen).
class HomeSearchBar extends StatefulWidget {
  // 40 for TopNavBar (matches the bell's own 40px circle instead of
  // towering over every other nav element at the field's original
  // Home-feed height) — Home's own usage keeps the original 54.
  final double height;
  final String hint;
  final String compactHint;
  final String recentKey;

  /// Suggestion pool; null = job / company / role terms.
  final List<String> Function()? termsBuilder;

  /// Shown before anything is typed and there is no history; null = popular roles.
  final List<String>? starters;

  /// Where a finished search goes; null = the jobs results list.
  final String Function(String query)? routeFor;

  const HomeSearchBar({
    super.key,
    this.height = 54,
    this.hint = 'Search jobs, companies, roles',
    this.compactHint = 'Search jobs, roles...',
    this.recentKey = _recentSearchesKey,
    this.termsBuilder,
    this.starters,
    this.routeFor,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _entry;

  List<String> _recent = [];
  late final List<String> _terms = (widget.termsBuilder ?? searchSuggestionTerms)();
  late final List<String> _starters = widget.starters ?? mockAllRoles.take(6).toList();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onChange);
    _controller.addListener(_onChange);
    _loadRecent();
  }

  @override
  void dispose() {
    _hide();
    _focusNode.removeListener(_onChange);
    _controller.removeListener(_onChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recent = prefs.getStringList(widget.recentKey) ?? []);
    _entry?.markNeedsBuild();
  }

  Future<void> _saveRecent(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [t, ..._recent.where((s) => s.toLowerCase() != t.toLowerCase())].take(_maxRecentSearches).toList();
    await prefs.setStringList(widget.recentKey, updated);
    if (!mounted) return;
    setState(() => _recent = updated);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.recentKey);
    if (!mounted) return;
    setState(() => _recent = []);
    _entry?.markNeedsBuild();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {}); // focus border + clear-icon visibility
    if (_focusNode.hasFocus) {
      _show();
    } else {
      // Delay the teardown so a tap on a dropdown row (which blurs the
      // field) still lands before the panel is removed.
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && !_focusNode.hasFocus) _hide();
      });
    }
  }

  void _show() {
    if (_entry != null) {
      _entry!.markNeedsBuild();
      return;
    }
    _entry = OverlayEntry(builder: _panel);
    Overlay.of(context).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void _submit(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    HapticFeedback.selectionClick();
    _saveRecent(t);
    _controller.clear();
    _focusNode.unfocus();
    _hide();
    context.push((widget.routeFor ?? _opportunityRoute)(t));
  }

  List<_Suggestion> _suggestions() {
    final typed = _controller.text.trim();
    if (typed.isNotEmpty) {
      final q = typed.toLowerCase();
      final tokens = searchTokens(typed);
      // Every typed word must be in the suggestion; ones that start with what was typed come first.
      final matching = _terms.where((t) => matchesAllTokens(tokens, [t])).toList()
        ..sort((a, b) {
          final aStarts = a.toLowerCase().startsWith(q) ? 0 : 1;
          final bStarts = b.toLowerCase().startsWith(q) ? 0 : 1;
          return aStarts != bStarts ? aStarts.compareTo(bStarts) : a.length.compareTo(b.length);
        });
      final matches = matching.take(6).toList();
      final rows = matches.map((m) => _Suggestion(m, Ionicons.search_outline, () => _submit(m))).toList();
      if (!matches.any((m) => m.toLowerCase() == q)) {
        rows.insert(0, _Suggestion('Search "$typed"', Ionicons.search_outline, () => _submit(typed)));
      }
      return rows;
    }
    if (_recent.isNotEmpty) {
      return _recent.map((s) => _Suggestion(s, Ionicons.time_outline, () => _submit(s))).toList();
    }
    return _starters.map((s) => _Suggestion(s, Ionicons.trending_up_outline, () => _submit(s))).toList();
  }

  Widget _panel(BuildContext _) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? (MediaQuery.sizeOf(context).width - AppSpacing.xl * 2);
    final rows = _suggestions();
    final typedEmpty = _controller.text.trim().isEmpty;
    final headerLabel = typedEmpty ? (_recent.isNotEmpty ? 'Recent searches' : 'Popular searches') : null;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 6),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 340),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.dropdown,
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              shrinkWrap: true,
              children: [
                if (headerLabel != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            headerLabel,
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.3),
                          ),
                        ),
                        if (_recent.isNotEmpty)
                          GestureDetector(
                            onTap: _clearRecent,
                            child: Text('Clear', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                          ),
                      ],
                    ),
                  ),
                for (final r in rows)
                  InkWell(
                    onTap: r.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(r.icon, size: 15, color: AppColors.gray500),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              r.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return CompositedTransformTarget(
      link: _link,
      child: Container(
        key: _fieldKey,
        // At the default 54, matches PillInput's own single-line pill
        // exactly (54 tall, AppSpacing.xl horizontal padding) — this widget
        // can't just BE a PillInput (it owns its own overlay/dropdown,
        // unlike PillInput's plain onChanged), but it's the same "search
        // field" role as Courses' PillInput-based search box, so the two
        // should read as identically sized, not a few px apart.
        height: widget.height,
        padding: EdgeInsets.symmetric(horizontal: widget.height < 54 ? AppSpacing.md : AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: focused ? AppColors.blue : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Ionicons.search_outline, size: widget.height < 54 ? 15 : 18, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: _submit,
                autofillHints: const [],
                cursorColor: AppColors.blue,
                style: AppTextStyles.body.copyWith(fontSize: widget.height < 54 ? 13 : 14, color: AppColors.ink),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.height < 54 ? widget.compactHint : widget.hint,
                  hintStyle: AppTextStyles.body.copyWith(fontSize: widget.height < 54 ? 13 : 14, color: AppColors.gray400),
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _controller.clear();
                  _focusNode.requestFocus();
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(Ionicons.close_circle, size: 16, color: AppColors.gray400),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Suggestion {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _Suggestion(this.label, this.icon, this.onTap);
}
