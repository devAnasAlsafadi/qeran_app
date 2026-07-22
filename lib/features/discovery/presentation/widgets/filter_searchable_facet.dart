import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_filter_option.dart';

/// A labelled facet for LARGE option sets (e.g. nationality) — a search field
/// over a selectable checklist, so a long list never becomes an unmanageable
/// chip wall. Wired to the same `isSelected` / `onTap` contract as the chip
/// facet, so it works for both single- and multi-select questions (the cubit
/// owns the toggle/replace semantics). Selected options always sort to the top
/// so a search never hides an active pick.
class FilterSearchableFacet extends StatefulWidget {
  const FilterSearchableFacet({
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
  State<FilterSearchableFacet> createState() => _FilterSearchableFacetState();
}

class _FilterSearchableFacetState extends State<FilterSearchableFacet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();
    final q = _query.trim().toLowerCase();
    final selected =
        widget.options.where((o) => widget.isSelected(o.value)).toList();
    final matches = widget.options
        .where((o) =>
            !widget.isSelected(o.value) &&
            (q.isEmpty || o.display.toLowerCase().contains(q)))
        .toList();
    final rows = [...selected, ...matches];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: QeranTypography.subtitle),
        QeranSpacing.vs8,
        QeranTextField(
          controller: _searchController,
          hint: LocaleKeys.discovery_filter_search_hint.t(context),
          prefix: const Icon(
            Icons.search_rounded,
            color: QeranColors.inkFaint,
            size: 20,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        QeranSpacing.vs8,
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
            child: Text(
              LocaleKeys.discovery_filter_search_empty.t(context),
              style: QeranTypography.caption
                  .copyWith(color: QeranColors.inkMuted),
            ),
          )
        else
          Column(
            children: [
              for (final o in rows)
                _OptionRow(
                  label: o.display,
                  selected: widget.isSelected(o.value),
                  onTap: () => widget.onTap(o.value),
                ),
            ],
          ),
      ],
    );
  }
}

/// One tappable checklist row — wine check + wine label when selected, faint
/// outline + neutral label otherwise.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.controlR,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: QeranSpacing.s12,
          horizontal: QeranSpacing.s8,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: selected ? QeranColors.wine : QeranColors.inkFaint,
              size: 22,
            ),
            QeranSpacing.hs12,
            Expanded(
              child: Text(
                label,
                style: QeranTypography.body.copyWith(
                  color: selected ? QeranColors.wine : QeranColors.inkStrong,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
