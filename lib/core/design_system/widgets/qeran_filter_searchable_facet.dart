import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_selectable_option.dart';
import 'qeran_text_field.dart';

part 'qeran_filter_searchable_facet_parts.dart';
part 'qeran_filter_searchable_facet_row.dart';

/// An expandable dropdown / accordion facet for LARGE option sets (e.g.
/// nationality). Shows a trigger field summarizing current selections when
/// collapsed, and expands into a searchable checklist when tapped.
///
/// Options render in the order given — this widget applies no sort. Ordering is
/// the caller's (ultimately the backend's) decision.
class QeranFilterSearchableFacet extends StatefulWidget {
  const QeranFilterSearchableFacet({
    super.key,
    required this.label,
    required this.options,
    required this.isSelected,
    required this.onTap,
    this.allowsMultiple = false,
    this.resetVersion = 0,
  });

  final String label;
  final List<QeranSelectableOption> options;
  final bool Function(String value) isSelected;
  final void Function(String value) onTap;

  /// Switches each row's indicator between a checkbox (many-of) and a radio
  /// (one-of). Cosmetic only — the host still decides what a tap DOES.
  ///
  /// Has to be told rather than inferred: [isSelected] alone cannot distinguish
  /// a multi facet with nothing chosen from a single one, and that is exactly
  /// the state where the cue matters most. Defaults to false so existing hosts
  /// keep the radio they render today.
  final bool allowsMultiple;

  /// Bumped by the host when a "clear all" happens, so the panel collapses and
  /// forgets its query instead of sitting open over a now-empty selection.
  final int resetVersion;

  @override
  State<QeranFilterSearchableFacet> createState() =>
      _QeranFilterSearchableFacetState();
}

class _QeranFilterSearchableFacetState
    extends State<QeranFilterSearchableFacet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant QeranFilterSearchableFacet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetVersion == widget.resetVersion) return;
    _searchController.clear();
    _searchFocus.unfocus();
    _query = '';
    _isExpanded = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Opening puts the cursor straight in the search box — the only reason to
  /// expand a long list is to narrow it. Deferred a frame because the field is
  /// not in the tree until this setState has rebuilt.
  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (!_isExpanded) {
      _searchFocus.unfocus();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isExpanded) _searchFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    final selected = widget.options
        .where((o) => widget.isSelected(o.value))
        .toList();
    final selectedText = selected.isEmpty
        ? null
        : selected.map((e) => e.display).join('، ');

    final q = _query.trim().toLowerCase();
    final matches = widget.options
        .where(
          (o) =>
              !widget.isSelected(o.value) &&
              (q.isEmpty || o.display.toLowerCase().contains(q)),
        )
        .toList();
    // Chosen options stay pinned to the top so a selection never scrolls out
    // of sight behind a query.
    final rows = [...selected, ...matches];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: QeranTypography.subtitle),
        QeranSpacing.vs8,
        _Trigger(
          label: widget.label,
          selectedText: selectedText,
          isExpanded: _isExpanded,
          onTap: _toggleExpanded,
        ),
        if (_isExpanded) ...[
          QeranSpacing.vs8,
          _Panel(
            controller: _searchController,
            focusNode: _searchFocus,
            onQueryChanged: (v) => setState(() => _query = v),
            rows: rows,
            isSelected: widget.isSelected,
            onTap: widget.onTap,
            allowsMultiple: widget.allowsMultiple,
          ),
        ],
      ],
    );
  }
}
