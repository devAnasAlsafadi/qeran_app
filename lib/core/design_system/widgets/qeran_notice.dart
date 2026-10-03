import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// A calm, standing notice inside a screen — "you can read, but not take part
/// yet" — not an error and not a toast. Gold-12 ground with a gold-40 edge,
/// a gold-deep icon at the first line, the text in strong ink; it wraps
/// freely at any text scale.
class QeranNotice extends StatelessWidget {
  const QeranNotice({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: QeranColors.goldDeep),
            QeranSpacing.hs12,
            Expanded(
              child: Text(
                text,
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.inkStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
