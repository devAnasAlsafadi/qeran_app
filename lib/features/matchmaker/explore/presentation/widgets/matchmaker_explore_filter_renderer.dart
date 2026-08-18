import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/widgets/qeran_filter_chip_facet.dart';
import '../../../../../core/design_system/widgets/qeran_filter_searchable_facet.dart';
import '../../../../../core/design_system/widgets/qeran_filter_text_facet.dart';
import '../../../../../core/design_system/widgets/qeran_range_slider.dart';
import '../../../../../core/design_system/widgets/qeran_selectable_option.dart';
import '../../../../discovery/domain/entities/discovery_filter_option.dart';
import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/domain/entities/filter_question_type.dart';
import '../blocs/matchmaker_explore_filter_cubit.dart';

/// Renders ONE backend-driven facet in the branded explore filter sheet:
///   • `isRange`  → the brand [QeranRangeSlider] (gold-active track).
///   • any option-bearing type → a chip / searchable facet, single or multi
///     per [DiscoveryFilterQuestion.effectiveIsMultiSelect].
///   • text → a branded text field.
/// Option facets render as chips or as a searchable checklist per
/// [DiscoveryFilterQuestion.effectiveIsSearchable] — the dashboard's flag when
/// it sent one, otherwise the shared [kQeranSearchableFacetThreshold] count. The
/// same widgets and the same rule the user app uses, so a nationality list
/// behaves identically on both sides. All wired to
/// [MatchmakerExploreFilterCubit]; the facets themselves come from `/filters`,
/// never hardcoded.
class MatchmakerExploreFilterRenderer extends StatelessWidget {
  const MatchmakerExploreFilterRenderer({
    super.key,
    required this.question,
    required this.selection,
    this.resetVersion = 0,
  });

  final DiscoveryFilterQuestion question;
  final DiscoveryFilterSelection? selection;

  /// Forwarded to the searchable facet so a "clear all" collapses it.
  final int resetVersion;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerExploreFilterCubit>();

    // Range FIRST — any question the dashboard flags `isRange` (age/height/
    // weight) uses the shared dual-thumb slider (RangeFrom/RangeTo).
    if (question.isRange) {
      final r = selection is RangeSelection ? selection as RangeSelection : null;
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
        // `isMultiSelect` decides, not the type. IDENTICAL to the user app's
        // renderer by construction: both read the same entity getter, so the
        // fallback can't drift between the two apps.
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
        // These arrive as ranges (handled above); a non-range one is dropped
        // by the cubit on load, so this is a defensive no-op.
        return const SizedBox.shrink();
    }
  }

  /// The seeded selection normalized to a flat value list — a sheet reopened
  /// after an earlier single-select apply carries a SingleValueSelection, and
  /// dropping it would silently clear a filter the matchmaker can still see
  /// applied. A single-select facet takes only the FIRST value of a multi (the
  /// cubit collapses seeded multis on load, but the dashboard can flip
  /// `isMultiSelect` while the sheet is open).
  List<String> _selectedValues({required bool isMulti}) => switch (selection) {
    MultiValueSelection(:final values) => isMulti
        ? values
        : values.take(1).toList(growable: false),
    SingleValueSelection(:final value) => <String>[value],
    _ => const <String>[],
  };

  /// Chips or a searchable checklist — the same `isSelected` / `onTap` contract
  /// either way, so the cubit's selection semantics are unchanged.
  /// [isSearchable] is the dashboard's answer when it gave one and the
  /// option-count fallback otherwise; this method does not second-guess it. The
  /// feature entity is adapted to the design-system option type here; the
  /// facets must not know a feature type.
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
