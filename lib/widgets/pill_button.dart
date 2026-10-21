import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Mirrors frontend/src/components/ui.tsx PillButton.
///
/// [primary] is the yellow call to action with an ink label (one per screen), [secondary] a white
/// button with a thin blue stroke and blue label (card-level CTAs like Apply), [ghost] a plain
/// blue text button and [dark] a solid blue button with a white label.
///
/// [outlineWhite] is for a solid blue surface (hero cards): transparent with a white stroke and
/// white label, so it recedes next to the yellow [primary] the way [secondary] does on white.
enum PillVariant { primary, secondary, ghost, dark, outlineWhite }

class PillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final bool loading;
  final bool disabled;
  final IconData? icon;

  /// Overrides [icon] when set — for brand marks (Google/Gmail) that need
  /// their real multi-color logo instead of a single-color IconData glyph.
  final Widget? iconWidget;
  final bool full;
  final Key? testKey;

  /// Smaller footprint for tight spaces (e.g. a card footer's Apply CTA)
  /// — same visual language, just a shorter/tighter build of the same button
  /// rather than a bespoke small-button widget.
  final bool compact;

  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PillVariant.primary,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.iconWidget,
    this.full = true,
    this.testKey,
    this.compact = false,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  bool get _isDisabled => widget.disabled || widget.loading;

  Color get _bg {
    switch (widget.variant) {
      case PillVariant.primary:
        return _pressed ? AppColors.brandPressed : AppColors.brand;
      case PillVariant.secondary:
        return AppColors.white;
      case PillVariant.dark:
        return _pressed ? AppColors.blueDark : AppColors.blue;
      case PillVariant.ghost:
      case PillVariant.outlineWhite:
        return Colors.transparent;
    }
  }

  Color get _fg {
    switch (widget.variant) {
      case PillVariant.primary:
        return AppColors.ink;
      case PillVariant.secondary:
      case PillVariant.ghost:
        return AppColors.blue;
      case PillVariant.dark:
      case PillVariant.outlineWhite:
        return AppColors.white;
    }
  }

  void _handleTap() {
    if (_isDisabled) return;
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.loading
        ? SizedBox(
            width: widget.compact ? 16 : 20,
            height: widget.compact ? 16 : 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.iconWidget != null) ...[
                SizedBox(
                  width: widget.compact ? 16 : 20,
                  height: widget.compact ? 16 : 20,
                  child: widget.iconWidget,
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.compact ? 16 : 20, color: _fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: widget.compact
                    ? AppTextStyles.body.copyWith(fontWeight: AppFontWeight.medium, color: _fg, fontSize: 12)
                    // semibold, matching Internshala's measured primary
                    // button label (14px/600).
                    : AppTextStyles.bodyLg.copyWith(fontWeight: AppFontWeight.semibold, color: _fg),
              ),
            ],
          );

    return GestureDetector(
      key: widget.testKey,
      onTapDown: _isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: _isDisabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: _isDisabled ? null : () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed && !_isDisabled ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _isDisabled ? 0.5 : (_pressed ? 0.92 : 1.0),
          duration: const Duration(milliseconds: 100),
          child: Container(
            // 44, not the old 46 — Naukri's primary buttons measured 38px;
            // splitting the difference keeps a comfortable tap target while
            // trimming the visible bulk. A fixed constant, not built from
            // AppSpacing tokens — 44 isn't itself on the 8pt grid, and
            // this used to be written as `AppSpacing.xxxl + AppSpacing.xs`
            // (correct back when xxxl was 40), which silently became 68
            // once the spacing grid was rebased to xxxl=64.
            height: widget.compact ? 32 : 44,
            width: widget.full ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? AppSpacing.md : AppSpacing.xl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: switch (widget.variant) {
                PillVariant.secondary => Border.all(color: AppColors.blue, width: 1.5),
                PillVariant.outlineWhite => Border.all(color: AppColors.white, width: 1.5),
                _ => null,
              },
              boxShadow: widget.variant == PillVariant.primary ? AppShadows.brand : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
