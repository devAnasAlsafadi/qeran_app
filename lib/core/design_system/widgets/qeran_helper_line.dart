import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// A line of help beside a field: a small icon, then a caption that wraps —
/// muted, or in danger when it says what's wrong. Under a [QeranTextField]
/// (its `helper`, and that field's errors in the same shape), or on its own
/// in a form — "your real name is private".
class QeranHelperLine extends StatelessWidget {
  const QeranHelperLine({
    super.key,
    required this.icon,
    required this.text,
    this.error = false,
  });

  /// [text] as an error: the error glyph, in danger.
  const QeranHelperLine.error(this.text, {super.key})
    : icon = Icons.error_outline_rounded,
      error = true;

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? QeranColors.danger : QeranColors.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        QeranSpacing.hs8,
        Flexible(
          child: Text(
            text,
            style: QeranTypography.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
