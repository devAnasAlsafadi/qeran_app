import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_filter_option.dart';

/// An expandable Dropdown / Accordion facet for LARGE option sets (e.g. nationality).
/// Shows a neat trigger field summarizing current selections when collapsed,
/// and expands into a searchable checklist when tapped.
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
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    final selectedList =
        widget.options.where((o) => widget.isSelected(o.value)).toList();
    final selectedText = selectedList.isEmpty
        ? null
        : selectedList.map((e) => e.display).join('، ');

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
        // Dropdown Header / Trigger Container
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: QeranRadii.controlR,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s16,
              vertical: QeranSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: QeranColors.creamSurface,
              borderRadius: QeranRadii.controlR,
              border: Border.all(
                color: selectedList.isNotEmpty
                    ? QeranColors.wine
                    : QeranColors.inkFaint.withValues(alpha: 0.3),
                width: selectedList.isNotEmpty ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedText ?? widget.label,
                    style: QeranTypography.body.copyWith(
                      color: selectedText != null
                          ? QeranColors.wine
                          : QeranColors.inkMuted,
                      fontWeight: selectedText != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: selectedList.isNotEmpty
                      ? QeranColors.wine
                      : QeranColors.inkFaint,
                ),
              ],
            ),
          ),
        ),

        // Expandable List Panel
        if (_isExpanded) ...[
          QeranSpacing.vs8,
          Container(
            padding: const EdgeInsets.all(QeranSpacing.s12),
            decoration: BoxDecoration(
              color: QeranColors.paper,
              borderRadius: QeranRadii.cardR,
              border: Border.all(
                color: QeranColors.inkFaint.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: QeranSpacing.s12),
                          child: Text(
                            LocaleKeys.discovery_filter_search_empty.t(context),
                            style: QeranTypography.caption
                                .copyWith(color: QeranColors.inkMuted),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final o = rows[i];
                            return _OptionRow(
                              label: o.display,
                              selected: widget.isSelected(o.value),
                              onTap: () => widget.onTap(o.value),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
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
