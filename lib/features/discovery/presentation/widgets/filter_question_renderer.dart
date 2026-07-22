import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_range_slider.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';

import '../../domain/entities/discovery_filter_option.dart';
import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import '../../domain/entities/filter_question_type.dart';
import '../blocs/discovery_filter_cubit.dart';
import 'filter_chip_facet.dart';
import 'filter_searchable_facet.dart';

/// Option-count cut-off: at or below this many options a facet renders as a
/// chip-group; above it, a searchable checklist ([FilterSearchableFacet]) so a
/// long list (e.g. nationality) never becomes an unmanageable chip wall. The
/// decision is purely count-based (backend-driven) — no per-question hardcoding.
const int _kSearchableThreshold = 10;

/// Renders ONE backend-driven filter facet on the branded discovery filter
/// sheet (mirrors the matchmaker explore filter's organization):
///   • `isRange`  → the brand [QeranRangeSlider] (gold-active track).
///   • checkbox / interests → a multi-select facet.
///   • select / radio / unknown(with options) → a single-select facet.
///   • text → a branded text field.
/// Option facets render as chips for small sets and a searchable checklist for
/// large ones. All wired to [DiscoveryFilterCubit] (the data/query layer is
/// untouched); the facets themselves come from `/filters`, never hardcoded.
class FilterQuestionRenderer extends StatelessWidget {
  final DiscoveryFilterQuestion question;
  final DiscoveryFilterSelection? selection;

  const FilterQuestionRenderer({
    super.key,
    required this.question,
    required this.selection,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DiscoveryFilterCubit>();

    // Range FIRST — any question flagged `isRange` (age/height/weight) uses
    // the shared dual-thumb slider (RangeFrom/RangeTo).
    if (question.isRange) {
      final r = selection is RangeSelection
          ? selection as RangeSelection
          : null;
      return QeranRangeSlider(
        label: question.label,
        min: question.effectiveMin,
        max: question.effectiveMax,
        start: r?.min ?? question.effectiveMin,
        end: r?.max ?? question.effectiveMax,
        unit: question.unit,
        onChanged: (min, max) => cubit.setRange(question.id, min, max),
      );
    }

    final options = question.options ?? const <DiscoveryFilterOption>[];

    switch (question.type) {
      case FilterQuestionType.checkbox:
      case FilterQuestionType.interests:
        final selected = selection is MultiValueSelection
            ? (selection as MultiValueSelection).values
            : const <String>[];
        return _optionsFacet(
          label: question.label,
          options: options,
          isSelected: selected.contains,
          onTap: (v) => cubit.toggleMultiValue(question.id, v),
        );
      case FilterQuestionType.select:
      case FilterQuestionType.radio:
      case FilterQuestionType.unknown:
        final value = selection is SingleValueSelection
            ? (selection as SingleValueSelection).value
            : null;
        return _optionsFacet(
          label: question.label,
          options: options,
          isSelected: (v) => v == value,
          onTap: (v) => cubit.setSingleValue(question.id, v),
        );
      case FilterQuestionType.text:
        return _TextFacet(
          label: question.label,
          initial: selection is SingleValueSelection
              ? (selection as SingleValueSelection).value
              : '',
          onChanged: (v) => cubit.setSingleValue(question.id, v),
        );
      case FilterQuestionType.date:
      case FilterQuestionType.height:
      case FilterQuestionType.weight:
        // Ranges are handled above; a non-range one is dropped by the cubit.
        return const SizedBox.shrink();
    }
  }

  /// Chips for small option sets, a searchable checklist for large ones — the
  /// same `isSelected` / `onTap` contract either way, so the cubit's single vs
  /// multi selection semantics are unchanged.
  Widget _optionsFacet({
    required String label,
    required List<DiscoveryFilterOption> options,
    required bool Function(String value) isSelected,
    required void Function(String value) onTap,
  }) {
    if (options.length > _kSearchableThreshold) {
      return FilterSearchableFacet(
        label: label,
        options: options,
        isSelected: isSelected,
        onTap: onTap,
      );
    }
    return FilterChipFacet(
      label: label,
      options: options,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}

/// A labelled free-text facet — a branded field feeding the same single-value
/// selection path.
class _TextFacet extends StatefulWidget {
  const _TextFacet({
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final String initial;
  final void Function(String value) onChanged;

  @override
  State<_TextFacet> createState() => _TextFacetState();
}

class _TextFacetState extends State<_TextFacet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: QeranTypography.subtitle),
        QeranSpacing.vs8,
        QeranTextField(
          controller: _controller,
          hint: widget.label,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
