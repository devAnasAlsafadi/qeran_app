import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/domain/entities/filter_question_type.dart';
import '../../../../discovery/presentation/widgets/filter_expandable_multi.dart';
import '../../../../discovery/presentation/widgets/filter_expandable_select.dart';
import '../../../../discovery/presentation/widgets/filter_text_field.dart';
import '../blocs/matchmaker_explore_filter_cubit.dart';
import 'matchmaker_explore_date_field.dart';
import 'matchmaker_explore_number_field.dart';

/// Parallel to discovery's `FilterQuestionRenderer` — same leaf sub-widgets
/// (reused, they're callback-driven), but wired to
/// [MatchmakerExploreFilterCubit] instead of `DiscoveryFilterCubit`, and with
/// NO range branch (ranges are dropped on load for explore). Discovery's
/// renderer is untouched.
class MatchmakerExploreFilterRenderer extends StatelessWidget {
  final DiscoveryFilterQuestion question;
  final DiscoveryFilterSelection? selection;

  const MatchmakerExploreFilterRenderer({
    super.key,
    required this.question,
    required this.selection,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerExploreFilterCubit>();

    switch (question.type) {
      case FilterQuestionType.checkbox:
      case FilterQuestionType.interests:
        return FilterExpandableMulti(
          question: question,
          selection:
              selection is MultiValueSelection ? selection as MultiValueSelection : null,
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
        // EXACT match on TextAnswer (yyyy-MM-dd) — single value, not a range.
        return MatchmakerExploreDateField(
          question: question,
          selection: selection is SingleValueSelection
              ? selection as SingleValueSelection
              : null,
          onChanged: (value) => cubit.setSingleValue(question.id, value),
        );
      case FilterQuestionType.height:
      case FilterQuestionType.weight:
        // EXACT match on a numeric TextAnswer — single value, not a range.
        return MatchmakerExploreNumberField(
          question: question,
          selection: selection is SingleValueSelection
              ? selection as SingleValueSelection
              : null,
          onChanged: (value) => cubit.setSingleValue(question.id, value),
        );
    }
  }
}
