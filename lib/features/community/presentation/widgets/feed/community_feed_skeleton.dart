import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';

/// A post card's shape while the first page loads (B3): the author, two
/// lines of text, a photo when [withMedia], and the footer.
class CommunityFeedSkeleton extends StatelessWidget {
  const CommunityFeedSkeleton({super.key, this.withMedia = false});

  final bool withMedia;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(QeranSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Author(),
                QeranSpacing.vs12,
                const _Line(0.92),
                QeranSpacing.vs12,
                const _Line(0.76),
                if (withMedia) ...[
                  QeranSpacing.vs12,
                  const QeranSkeleton.box(
                    height: 200,
                    radius: QeranRadii.control,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: QeranColors.divider),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: QeranSpacing.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                QeranSkeleton(width: 60, height: 12),
                QeranSkeleton(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Author extends StatelessWidget {
  const _Author();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        QeranSkeleton.circle(size: 44),
        QeranSpacing.hs12,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QeranSkeleton(width: 120, height: 12),
            SizedBox(height: QeranSpacing.s6),
            QeranSkeleton(width: 70, height: 10),
          ],
        ),
      ],
    );
  }
}

/// A line of text, [share] of the card's width.
class _Line extends StatelessWidget {
  const _Line(this.share);

  final double share;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: share,
      child: const QeranSkeleton(height: 12),
    );
  }
}
