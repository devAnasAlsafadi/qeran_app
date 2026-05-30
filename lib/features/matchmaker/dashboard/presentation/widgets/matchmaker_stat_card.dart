import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';

/// A single dashboard counter: gold-tinted icon disc, the count in
/// tabular numerals, and a wrapping label. Tapping jumps to the related
/// tab (wired by the grid). Composes [QeranCard] — no ad-hoc container.
class MatchmakerStatCard extends StatelessWidget {
  const MatchmakerStatCard({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      onTap: onTap,
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconDisc(icon: icon),
          QeranSpacing.vs12,
          Text(
            '$count',
            style: QeranTypography.numeric.copyWith(fontSize: 28),
          ),
          QeranSpacing.vs4,
          Text(
            label,
            style: QeranTypography.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _IconDisc extends StatelessWidget {
  const _IconDisc({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: QeranColors.gold12,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: QeranColors.wine),
    );
  }
}
