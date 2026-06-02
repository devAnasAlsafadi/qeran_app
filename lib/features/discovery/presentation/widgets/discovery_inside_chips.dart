import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../domain/entities/placement_item.dart';
import '_chip_display.dart';
import '_placement_icons.dart';

/// Outlined tag chips with a wine icon, used inside the card body.
class DiscoveryInsideChips extends StatelessWidget {
  final List<PlacementItem> items;

  const DiscoveryInsideChips({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s8,
      children: items.map((i) => _OutlinedTag(item: i)).toList(),
    );
  }
}

class _OutlinedTag extends StatelessWidget {
  final PlacementItem item;
  const _OutlinedTag({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconForQuestionId(item.questionId),
            size: 16,
            color: QeranColors.wine,
          ),
          const SizedBox(width: QeranSpacing.s6),
          Text(
            chipDisplay(item, context),
            style: QeranTypography.label,
          ),
        ],
      ),
    );
  }
}
