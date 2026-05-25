import 'package:flutter/material.dart';

import '../effects/ring_motif.dart';
import '../motion/soft_scale_in.dart';
import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_button.dart';

/// Brand-aligned success surface. Two overlapping circles (wine + gold)
/// at the top inspired by the identity's "match" emotional graphic,
/// then title, optional message, and an optional continue CTA.
class QeranSuccessState extends StatelessWidget {
  const QeranSuccessState({
    super.key,
    required this.title,
    this.message,
    this.continueLabel,
    this.onContinue,
  });

  final String title;
  final String? message;
  final String? continueLabel;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(QeranSpacing.s24),
          child: SoftScaleIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TwoCircleMark(),
                QeranSpacing.vs24,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: QeranTypography.headline,
                ),
                if (message != null) ...[
                  QeranSpacing.vs8,
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: QeranTypography.body,
                  ),
                ],
                if (continueLabel != null && onContinue != null) ...[
                  QeranSpacing.vs24,
                  QeranButton(
                    label: continueLabel!,
                    onPressed: onContinue,
                    variant: QeranButtonVariant.primary,
                    fullWidth: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two overlapping circles (wine + gold) — the identity's match mark.
class _TwoCircleMark extends StatelessWidget {
  const _TwoCircleMark();

  static const double _size = 56;
  static const double _overlap = 20;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size * 2 - _overlap,
      height: _size,
      child: Stack(
        children: [
          const Positioned.fill(
            child: RingMotif(
              opacity: 0.06,
              size: _size * 2,
              ringCount: 1,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _Disc(color: QeranColors.wine),
          ),
          Positioned(
            left: _size - _overlap,
            top: 0,
            child: _Disc(color: QeranColors.gold),
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _TwoCircleMark._size,
      height: _TwoCircleMark._size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.paper, width: 2),
      ),
    );
  }
}
