import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';

/// A white overview tile — wine count, wine-tinted icon chip, and a
/// direction-aware trailing chevron. Composes the standard [QeranCard]
/// (paper + e2), no ad-hoc container.
class MatchmakerOverviewTile extends StatelessWidget {
  const MatchmakerOverviewTile({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      onTap: onTap,
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconChip(icon: icon),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: QeranColors.wine40,
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$count',
            style: QeranTypography.numeric.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: QeranColors.wine,
            ),
          ),
          const SizedBox(height: QeranSpacing.s2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: QeranTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: QeranColors.wine06,
        borderRadius: QeranRadii.controlR,
      ),
      child: Icon(icon, size: 22, color: QeranColors.wine),
    );
  }
}
