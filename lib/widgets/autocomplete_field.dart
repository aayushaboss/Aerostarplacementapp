import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'pill_input.dart';

/// Type-ahead text field — start typing and matching options show in a
/// floating panel above the field, tap one to fill it in. Replaces the old
/// tap-to-open, search-in-a-sheet pattern (`SearchableSelect`) for fields
/// like city, college, and course, where typing a few letters and picking
/// from an inline list is faster than opening a full-screen picker every
/// time. Typed text that doesn't match anything is still accepted as-is
/// (there's no dedicated "custom entry" mode — whatever's typed is the
/// value).
///
/// The suggestion panel is a floating overlay, not a widget in the normal
/// layout flow — it used to sit as a sibling below (then above) the field,
/// which meant the field itself physically moved every time the list grew
/// or shrank while typing. An overlay leaves the field's position fixed no
/// matter how many suggestions show up.
class AutocompleteField extends StatefulWidget {
  final String? value;
  final String placeholder;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onChanged;

  /// Fires only when a suggestion is tapped from the dropdown — distinct
  /// from [onChanged], which also fires on every keystroke. Use this to
  /// commit a pick immediately (e.g. add it as a chip) without needing a
  /// separate confirm step, while free typing still just edits the field.
  final ValueChanged<String>? onSelected;

  /// Fires on the keyboard's Enter/Done action — the free-text equivalent
  /// of [onSelected], for committing a value that isn't in [options].
  final ValueChanged<String>? onSubmitted;

  final int maxSuggestions;
  final FocusNode? focusNode;

  /// Lets a caller keep its own read/write handle on the field's text (e.g.
  /// to fill it programmatically from a suggestion chip elsewhere on
  /// screen, or read it back at submit time) — optional, since most
  /// existing call sites just want [value] as a one-time seed and don't
  /// need external access. Owned and disposed internally when omitted,
  /// exactly like [TextField.controller].
  final TextEditingController? controller;

  const AutocompleteField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.options,
    required this.onChanged,
    this.onSelected,
    this.onSubmitted,
    this.maxSuggestions = 6,
    this.focusNode,
    this.controller,
  });

  @override
  State<AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<AutocompleteField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _removeOverlay();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    widget.onChanged(text);
    final q = text.trim().toLowerCase();
    setState(() {
      _suggestions = q.isEmpty ? const [] : widget.options.where((o) => o.toLowerCase().contains(q)).take(widget.maxSuggestions).toList();
    });
    _updateOverlay();
  }

  void _select(String option) {
    widget.onChanged(option);
    if (widget.onSelected != null) {
      // "Commit and clear" mode — the field owns its own reset instead of
      // relying on the parent to feed a new `value` back in (which
      // wouldn't even work: `_controller` only ever seeds from `value`
      // once, in initState).
      widget.onSelected!(option);
      _controller.clear();
    } else {
      _controller.text = option;
      _controller.selection = TextSelection.collapsed(offset: option.length);
      // Tapping a suggestion is the same "field answered, move on" signal
      // as typing it out and hitting the keyboard's own submit — without
      // this, picking from the dropdown filled the field but left it
      // sitting there with no way forward except a second, separate tap.
      widget.onSubmitted?.call(option);
    }
    setState(() => _suggestions = const []);
    _removeOverlay();
  }

  void _handleSubmitted(String text) {
    final trimmed = text.trim();
    if (widget.onSubmitted == null || trimmed.isEmpty) return;
    widget.onSubmitted!(trimmed);
    // Only when onSelected is also wired — that combination means this
    // field's own intent is "type a value, commit it, clear for the next
    // one" (e.g. adding cities one at a time in opportunity_filter_screen.
    // dart, where onSelected/onSubmitted both point at the same add
    // handler). Without onSelected, onSubmitted means "the field is done,
    // move on" — the resume builder's single-value fields (Institution,
    // Degree, Company, Role) rely on the typed text staying put, since it's
    // read back afterward as the answer itself; clearing it here used to
    // silently blank it the instant the keyboard's submit fired.
    if (widget.onSelected != null) {
      _controller.clear();
      widget.onChanged('');
    }
    setState(() => _suggestions = const []);
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_suggestions.isEmpty) {
      _removeOverlay();
      return;
    }
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 0;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, AppSpacing.xs),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppShadows.dropdown,
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final option = _suggestions[i];
                return InkWell(
                  onTap: () => _select(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Text(option, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyedSubtree(
        key: _fieldKey,
        child: PillInput(
          controller: _controller,
          focusNode: widget.focusNode,
          placeholder: widget.placeholder,
          icon: widget.icon,
          onChanged: _onTextChanged,
          onSubmitted: widget.onSubmitted != null ? _handleSubmitted : null,
          textInputAction: widget.onSubmitted != null ? TextInputAction.done : null,
        ),
      ),
    );
  }
}
