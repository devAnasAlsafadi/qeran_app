import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import '../../domain/entities/filter_question_type.dart';
import '../blocs/discovery_filter_cubit.dart';
import 'filter_expandable_multi.dart';
import 'filter_expandable_select.dart';
import 'filter_range_field.dart';
import 'filter_text_field.dart';

/// Two-dimensional dispatcher.
///
/// 1. `isRange == true` → range slider (covers date/height/weight/any
///    future range-flagged type).
/// 2. Otherwise switch on [FilterQuestionType]:
///    * `select` / `radio` → single-choice expandable.
///    * `checkbox` / `interests` → multi-choice expandable.
///    * `text` → exact-match text input.
///    * `unknown` + options → single-choice fallback.
///    * range-types-without-isRange / `unknown` without options →
///      filtered upstream by `DiscoveryFilterCubit._filterOutUnusable`,
///      so they never reach this renderer.
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

    if (question.isRange) {
      return FilterRangeField(
        question: question,
        selection: selection is RangeSelection
            ? selection as RangeSelection
            : null,
        onChanged: (min, max) => cubit.setRange(question.id, min, max),
      );
    }

    switch (question.type) {
      case FilterQuestionType.checkbox:
      case FilterQuestionType.interests:
        return FilterExpandableMulti(
          question: question,
          selection: selection is MultiValueSelection
              ? selection as MultiValueSelection
              : null,
          onToggle: (value) => cubit.toggleMultiValue(question.id, value),
        );
      case FilterQuestionType.text:
        return FilterTextField(
          question: question,
          selection: selection is SingleValueSelection
              ? selection as SingleValueSelection
              : null,
          onChanged: (value) => cubit.setSingleValue(question.id, value),
        );
      case FilterQuestionType.select:
      case FilterQuestionType.radio:
      case FilterQuestionType.unknown:
        return FilterExpandableSelect(
          question: question,
          selection: selection is SingleValueSelection
              ? selection as SingleValueSelection
              : null,
          onChanged: (value) => cubit.setSingleValue(question.id, value),
        );
      case FilterQuestionType.date:
      case FilterQuestionType.height:
      case FilterQuestionType.weight:
        // Filtered upstream when isRange is false. Defensive fallback —
        // never expected to render.
        return const SizedBox.shrink();
    }
  }
}
