import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/editable_question.dart';
import '../blocs/profile_edit/profile_edit_cubit.dart';
import '../blocs/profile_edit/profile_edit_state.dart';
import '../widgets/edit/profile_edit_renderer.dart';
import 'profile_edit_field.dart';

/// A single labelled edit field: the question label + the type-specific edit
/// input ([ProfileEditRenderer]). The current value is read from cubit state
/// via a per-field [BlocSelector] (only this field rebuilds on its own edit),
/// and changes flow back through `updateAnswer`.
class ProfileEditQuestionField extends StatelessWidget {
  final EditableQuestion question;

  const ProfileEditQuestionField({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileEditCubit>();
    return BlocSelector<ProfileEditCubit, ProfileEditState,
        ({dynamic value, bool invalid})>(
      selector: (state) => state is ProfileEditLoaded
          ? (
              value: state.answers[question.questionId],
              invalid: state.invalidIds.contains(question.questionId),
            )
          : (value: null, invalid: false),
      builder: (context, data) => ProfileEditField(
        label: question.text,
        isRequired: question.isRequired,
        isInvalid: data.invalid,
        child: ProfileEditRenderer(
          question: question,
          currentAnswer: data.value,
          onAnswerChanged: (v) => cubit.updateAnswer(question.questionId, v),
        ),
      ),
    );
  }
}
