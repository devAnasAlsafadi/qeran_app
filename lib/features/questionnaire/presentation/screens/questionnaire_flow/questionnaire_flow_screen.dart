import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/gender.dart';
import '../../../domain/entities/question_entity.dart';
import '../../blocs/questionnaire_cubit.dart';
import 'widgets/questionnaire_flow_body.dart';

class QuestionnaireFlowScreen extends StatelessWidget {
  final List<QuestionEntity>? questions;

  const QuestionnaireFlowScreen({super.key, this.questions});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<QuestionnaireCubit>();
        if (questions != null) {
          cubit.startFlow(questions!);
        } else {
          // Resume path: when Splash routes here directly (e.g. after a
          // restart with a saved draft), fetch the questions for the
          // previously-chosen gender. Storage holds the API value
          // ('Male' / 'Female'), so compare case-insensitively.
          sl<SharedPrefService>().get<String>(StorageKeys.gender).then((g) {
            final gender =
                g?.toLowerCase() == 'female' ? Gender.female : Gender.male;
            cubit.fetchQuestions(gender: gender);
          });
        }
        return cubit;
      },
      child: const QuestionnaireFlowBody(),
    );
  }
}
