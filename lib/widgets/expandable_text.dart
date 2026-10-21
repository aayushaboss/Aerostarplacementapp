import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// A block of text truncated to [maxLines] with a "View more" toggle that
/// only appears when the text actually overflows that many lines at the
/// available width — a description that already fits shows no toggle at
/// all, same as a plain [Text]. Tapping "View more" expands to the full
/// text with a "View less" toggle to collapse back.
///
/// Uses [LayoutBuilder] + [TextPainter] to measure overflow up front rather
/// than rendering an ellipsis first and reacting to it, since Flutter's
/// [Text] widget doesn't expose "did this actually get truncated" on its
/// own.
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle style;

  const ExpandableText({super.key, required this.text, this.maxLines = 3, required this.style});

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: widget.style);
        final painter = TextPainter(text: span, maxLines: widget.maxLines, textDirection: Directionality.of(context))..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    _expanded ? 'View less' : 'View more',
                    style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
