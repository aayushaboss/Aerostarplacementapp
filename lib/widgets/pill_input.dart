import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Mirrors frontend/src/components/ui.tsx PillInput.
class PillInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final bool onBrand;
  final String? error;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final Key? testKey;

  /// >1 turns this into a growing multi-line box instead of the fixed-54dp
  /// single-line pill (e.g. for a "describe your role" answer) — the box's
  /// height then follows [minLines]/[maxLines] instead of being locked to
  /// 54, everything else about the pill (border, radius, focus ring) stays
  /// the same. Every existing call site leaves this at the default 1, so
  /// nothing about today's single-line pills changes.
  final int maxLines;
  final int? minLines;

  /// When true, focusing this field scrolls it to the top of its enclosing
  /// Scrollable — for a field that's the last thing before a commit button
  /// (e.g. "Add education") that the keyboard would otherwise cover with no
  /// way to tell the button is still there. Off by default: this alignment
  /// has no "already visible, skip" guard, so turning it on everywhere
  /// would forcibly snap-scroll fields that never had this problem (a
  /// short field with nothing below it) on every focus.
  final bool scrollIntoViewOnFocus;

  const PillInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    this.onBrand = false,
    this.error,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.testKey,
    this.maxLines = 1,
    this.minLines,
    this.scrollIntoViewOnFocus = false,
  });

  @override
  State<PillInput> createState() => _PillInputState();
}

class _PillInputState extends State<PillInput> {
  bool _focused = false;
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.error != null
        ? AppColors.error
        : (_focused ? AppColors.blue : Colors.transparent);
    final multiline = widget.maxLines != 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // isCollapsed below shrinks the TextField's own tappable/focusable
        // area down to just the tight text/hint glyph line, well short of
        // this pill's full padded height — without this wrapper, taps
        // anywhere else in the pill (most of its vertical space) silently
        // miss and never focus the field.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _focusNode.requestFocus(),
          child: Container(
            height: multiline ? null : 54,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: multiline ? AppSpacing.lg : 0),
            decoration: BoxDecoration(
              color: widget.onBrand ? AppColors.white : AppColors.offWhite,
              borderRadius: BorderRadius.circular(multiline ? AppRadius.lg : 999),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Padding(
                    padding: EdgeInsets.only(top: multiline ? AppSpacing.xs : 0),
                    child: Icon(widget.icon, size: 18, color: AppColors.gray500),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Focus(
                    onFocusChange: (has) {
                      setState(() => _focused = has);
                      if (has && widget.scrollIntoViewOnFocus) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          Scrollable.ensureVisible(
                            context,
                            alignment: 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        });
                      }
                    },
                    child: TextField(
                      key: widget.testKey,
                      controller: widget.controller,
                      focusNode: widget.focusNode ?? _focusNode,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      obscureText: widget.obscureText,
                      maxLength: widget.maxLength,
                      inputFormatters: widget.inputFormatters,
                      maxLines: widget.maxLines,
                      minLines: widget.minLines,
                      autofillHints: const [],
                      style: AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        // Regular weight, not bodyLg's inherited medium — a
                        // placeholder is a hint, not content, and reading
                        // heavier than the actual field label above it
                        // inverts the hierarchy (the "question" should read
                        // stronger than its own example answer).
                        hintStyle: AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.gray400, fontWeight: AppFontWeight.regular),
                        border: InputBorder.none,
                        isCollapsed: true,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.lg),
            child: Text(
              widget.error!,
              style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
