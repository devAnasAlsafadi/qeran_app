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
/// The FALLBACK, not the rule. The backend's `isSearchable` has since shipped
/// and wins outright when present, so this count is consulted only for a
/// question the dashboard has not decided — see
/// `DiscoveryFilterQuestion.effectiveIsSearchable`. Lives here so that, when it
/// is consulted, both apps cut over at the same number.
const int kQeranSearchableFacetThreshold = 10;

/// A labelled facet whose options are selectable chips — selected = solid wine
/// (`score`), unselected = paper + wine border (`inside`).
///
/// Selection state is the chip's own fill, so unlike
/// [QeranFilterSearchableFacet] there is no per-option indicator and nothing
/// distinguishes a single- from a multi-select group: two filled chips already
/// say "more than one allowed".
///
/// For small option sets only; large sets belong in
/// [QeranFilterSearchableFacet]. The `isSelected` / `onTap` contract is
/// identical across both so a host can swap between them without changing its
/// selection semantics.
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
