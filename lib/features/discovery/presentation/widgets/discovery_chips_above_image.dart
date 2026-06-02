import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_value.dart';
import '_placement_icons.dart';

/// Translucent dark-wine pill chips overlaid at the top of the blurred
/// image. One per `aboveImage` placement item.
class DiscoveryChipsAboveImage extends StatelessWidget {
  final List<PlacementItem> items;

  const DiscoveryChipsAboveImage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s8,
      children: items.map((i) => _PillChip(item: i)).toList(),
    );
  }
}

class _PillChip extends StatelessWidget {
  final PlacementItem item;
  const _PillChip({required this.item});

  @override
  Widget build(BuildContext context) {
    // Dark-wine translucent pill with light text + a light hairline, so
    // it reads as an image overlay rather than a form chip (per Figma
    // `home.png`) while staying on the brand wine scrim.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: QeranColors.overlayTintDark,
        borderRadius: QeranRadii.pill,
        border: Border.all(
          color: QeranColors.paper.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconForQuestionId(item.questionId),
            size: 14,
            color: QeranColors.paper,
          ),
          const SizedBox(width: QeranSpacing.s6),
          Text(
            _displayText(item.display),
            style: QeranTypography.label.copyWith(color: QeranColors.paper),
          ),
        ],
      ),
    );
  }

  String _displayText(PlacementValue value) {
    return switch (value) {
      PlacementSingle(value: final v) => v,
      PlacementMulti(values: final vs) => vs.join('، '),
    };
  }
}
