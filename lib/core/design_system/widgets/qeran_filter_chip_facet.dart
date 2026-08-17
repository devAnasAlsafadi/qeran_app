import 'package:flutter/material.dart';

import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_chip.dart';
import 'qeran_selectable_option.dart';

/// Option-count cut-off shared by every facet host: at or below this many
/// options a facet renders as a chip-group; above it, a
/// [QeranFilterSearchableFacet] so a long list (e.g. nationality) never becomes
/// an unmanageable chip wall.
///
/// The decision is purely count-based — no per-question hardcoding — and lives
/// here so both apps cut over at the same number. Should the backend ever ship
/// an `isSearchable` flag, this is the single place that stops being consulted.
const int kQeranSearchableFacetThreshold = 10;

/// A labelled facet whose options are selectable chips — selected = solid wine
/// (`score`), unselected = paper + wine border (`inside`).
///
/// For small option sets only; large sets belong in
/// [QeranFilterSearchableFacet]. The `isSelected` / `onTap` contract is
/// identical across both so a host can swap on
/// [kQeranSearchableFacetThreshold] without changing its selection semantics.
class QeranFilterChipFacet extends StatelessWidget {
  const QeranFilterChipFacet({
    super.key,
    required this.label,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final List<QeranSelectableOption> options;
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
