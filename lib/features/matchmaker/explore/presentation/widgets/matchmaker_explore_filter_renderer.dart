import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/design_system/widgets/qeran_range_slider.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../discovery/domain/entities/discovery_filter_option.dart';
import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/domain/entities/filter_question_type.dart';
import '../blocs/matchmaker_explore_filter_cubit.dart';

/// Renders ONE backend-driven facet in the branded explore filter sheet:
///   • `isRange`  → the brand [QeranRangeSlider] (gold-active track).
///   • checkbox / interests → a multi-select chip-group.
///   • select / radio / unknown(with options) → a single-select chip-group.
///   • text → a branded text field.
/// All wired to [MatchmakerExploreFilterCubit] (the data/query layer is
/// untouched); the facets themselves come from `/filters`, never hardcoded.
class MatchmakerExploreFilterRenderer extends StatelessWidget {
  const MatchmakerExploreFilterRenderer({
    super.key,
    required this.question,
    required this.selection,
  });

  final DiscoveryFilterQuestion question;
  final DiscoveryFilterSelection? selection;

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
        final selected = selection is MultiValueSelection
            ? (selection as MultiValueSelection).values
            : const <String>[];
        return _ChipFacet(
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
        return _ChipFacet(
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
        // These arrive as ranges (handled above); a non-range one is dropped
        // by the cubit on load, so this is a defensive no-op.
        return const SizedBox.shrink();
    }
  }
}

/// A labelled facet section whose options are selectable chips — selected =
/// solid wine (`score`), unselected = paper + wine-12 border (`inside`).
class _ChipFacet extends StatelessWidget {
  const _ChipFacet({
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

/// A labelled free-text facet (rare) — a branded field feeding the same
/// single-value selection path.
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
