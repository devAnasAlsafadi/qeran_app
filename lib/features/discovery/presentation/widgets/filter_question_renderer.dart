import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_chip_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_searchable_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_text_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_range_slider.dart';
import 'package:qeran/core/design_system/widgets/qeran_selectable_option.dart';

import '../../domain/entities/discovery_filter_option.dart';
import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import '../../domain/entities/filter_question_type.dart';
import '../blocs/discovery_filter_cubit.dart';

/// Renders ONE backend-driven filter facet on the branded discovery filter
/// sheet (mirrors the matchmaker explore filter's organization):
///   • `isRange`  → the brand [QeranRangeSlider] (gold-active track).
///   • any option-bearing type → a chip / searchable facet, single or multi
///     per [DiscoveryFilterQuestion.effectiveIsMultiSelect].
///   • text → a branded text field.
/// Option facets render as chips or as a searchable checklist per
/// [DiscoveryFilterQuestion.effectiveIsSearchable] — the dashboard's flag when
/// it sent one, otherwise the [kQeranSearchableFacetThreshold] count. All wired
/// to [DiscoveryFilterCubit] (the data/query layer is untouched); the facets
/// themselves come from `/filters`, never hardcoded.
class FilterQuestionRenderer extends StatelessWidget {
  final DiscoveryFilterQuestion question;
  final DiscoveryFilterSelection? selection;
  final int resetVersion;

  const FilterQuestionRenderer({
    super.key,
    required this.question,
    required this.selection,
    this.resetVersion = 0,
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
      case FilterQuestionType.select:
      case FilterQuestionType.radio:
      case FilterQuestionType.unknown:
        // One branch for every option-bearing type — the dashboard's
        // `isMultiSelect`, not the type, decides which cubit path a tap takes.
        final isMulti = question.effectiveIsMultiSelect;
        final selected = _selectedValues(isMulti: isMulti);
        return _optionsFacet(
          label: question.label,
          options: options,
          isSearchable: question.effectiveIsSearchable(
            optionCountThreshold: kQeranSearchableFacetThreshold,
          ),
          allowsMultiple: isMulti,
          isSelected: selected.contains,
          onTap: isMulti
              ? (v) => cubit.toggleMultiValue(question.id, v)
              : (v) => cubit.setSingleValue(question.id, v),
        );
      case FilterQuestionType.text:
        return QeranFilterTextFacet(
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

  /// The seeded selection normalized to a flat value list, so either shape
  /// renders correctly regardless of which one the sheet was opened with.
  ///
  /// A single-select facet takes only the FIRST value of a multi: the cubit
  /// collapses seeded multis on load, but the dashboard can flip
  /// `isMultiSelect` while the sheet is open, and showing three selected chips
  /// on a facet that only accepts one would be a lie.
  List<String> _selectedValues({required bool isMulti}) => switch (selection) {
    MultiValueSelection(:final values) => isMulti
        ? values
        : values.take(1).toList(growable: false),
    SingleValueSelection(:final value) => <String>[value],
    _ => const <String>[],
  };

  /// Chips or a searchable checklist — the same `isSelected` / `onTap` contract
  /// either way, so the cubit's single vs multi selection semantics are
  /// unchanged. [isSearchable] is the dashboard's answer when it gave one and
  /// the option-count fallback otherwise; this method does not second-guess it.
  Widget _optionsFacet({
    required String label,
    required List<DiscoveryFilterOption> options,
    required bool isSearchable,
    required bool allowsMultiple,
    required bool Function(String value) isSelected,
    required void Function(String value) onTap,
  }) {
    final dsOptions = options
        .map((o) => QeranSelectableOption(value: o.value, display: o.display))
        .toList(growable: false);
    if (isSearchable) {
      return QeranFilterSearchableFacet(
        label: label,
        options: dsOptions,
        isSelected: isSelected,
        onTap: onTap,
        allowsMultiple: allowsMultiple,
        resetVersion: resetVersion,
      );
    }
    return QeranFilterChipFacet(
      label: label,
      options: dsOptions,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
