import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

import '../../domain/entities/discovery_filter_option.dart';

/// A labelled facet whose options are selectable chips — selected = solid wine
/// (`score`), unselected = paper + wine border (`inside`). Used for small
/// option sets; large sets render as a [FilterSearchableFacet] instead.
class FilterChipFacet extends StatelessWidget {
  const FilterChipFacet({
    super.key,
    required this.label,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final List<DiscoveryFilterOption> options;
  final bool Function(String value) isSelected;
  final void Function(String value) onTap;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: QeranTypography.subtitle),
        QeranSpacing.vs8,
        Wrap(
          spacing: QeranSpacing.s8,
          runSpacing: QeranSpacing.s8,
          children: [
            for (final o in options)
              QeranChip(
                label: o.display,
                variant: isSelected(o.value)
                    ? QeranChipVariant.score
                    : QeranChipVariant.inside,
                onTap: () => onTap(o.value),
              ),
          ],
        ),
      ],
    );
  }
}
