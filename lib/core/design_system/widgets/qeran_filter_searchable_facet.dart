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
    this.resetVersion = 0,
  });

  final String label;
  final List<QeranSelectableOption> options;
  final bool Function(String value) isSelected;
  final void Function(String value) onTap;

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
          ),
        ],
      ],
    );
  }
}

/// The collapsed dropdown header: summarizes the selection, or falls back to
/// the facet label as a placeholder. Wine border + wine bold text once
/// anything is chosen.
class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.label,
    required this.selectedText,
    required this.isExpanded,
    required this.onTap,
  });

  final String label;
  final String? selectedText;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = selectedText != null;
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.controlR,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s16,
          vertical: QeranSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.controlR,
          border: Border.all(
            color: active
                ? QeranColors.wine
                : QeranColors.inkFaint.withValues(alpha: 0.3),
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedText ?? label,
                style: QeranTypography.body.copyWith(
                  color: active ? QeranColors.wine : QeranColors.inkMuted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: active ? QeranColors.wine : QeranColors.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}
