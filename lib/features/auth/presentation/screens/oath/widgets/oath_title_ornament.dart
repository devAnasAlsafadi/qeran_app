import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// Decorative `─ ◆ ─` motif used in place of the flat 2×60 divider under
/// the oath title. Two short burgundy hair-lines flank a small diamond
/// icon. Keeps the screen looking matrimonial / luxury without needing
/// an SVG asset.
class OathTitleOrnament extends StatelessWidget {
  final double lineLength;
  const OathTitleOrnament({super.key, this.lineLength = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _OrnamentLine(width: lineLength),
        QeranSpacing.hs8,
        const Icon(
          Icons.diamond_outlined,
          size: 12,
          color: QeranColors.wine,
        ),
        QeranSpacing.hs8,
        _OrnamentLine(width: lineLength),
      ],
    );
  }
}

class _OrnamentLine extends StatelessWidget {
  final double width;
  const _OrnamentLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QeranColors.wine.withValues(alpha: 0.0),
            QeranColors.wine.withValues(alpha: 0.55),
          ],
        ),
      ),
    );
  }
}
