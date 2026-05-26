import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_item.dart';
import '../../../domain/entities/placement_value.dart';

/// Renders the `insideCard` placement (height, weight, marital status,
/// ethnicity, etc.) as outlined tag chips. Same widget feeds the
/// Discovery card preview AND the full details screen — no parallel
/// chip rendering.
class InsideChipsSection extends StatelessWidget {
  final Placement placement;
  const InsideChipsSection({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    if (placement.items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: QeranSpacing.s12,
      runSpacing: QeranSpacing.s12,
      children: placement.items
          .map(
            (i) => QeranChip(
              label: _label(i),
              variant: QeranChipVariant.inside,
              compact: true,
            ),
          )
          .toList(growable: false),
    );
  }

  String _label(PlacementItem item) {
    return switch (item.display) {
      PlacementSingle(value: final s) => s,
      PlacementMulti(values: final vs) => vs.join(' · '),
    };
  }
}
