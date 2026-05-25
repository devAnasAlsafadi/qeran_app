import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';

sealed class QuestionnaireState {}

final class QuestionnaireInitial extends QuestionnaireState {}

final class QuestionnaireLoading extends QuestionnaireState {}

final class QuestionnaireFetched extends QuestionnaireState {
  final List<QuestionEntity> questions;

  QuestionnaireFetched(this.questions);
}

final class QuestionnaireFailure extends QuestionnaireState {
  final String message;

  QuestionnaireFailure(this.message);
}

/// Active question-answering session state.
final class QuestionnaireInProgress extends QuestionnaireState {
  final List<QuestionEntity> questions;
  final int currentIndex;
  final Map<String, dynamic> answers;

  QuestionnaireInProgress({
    required this.questions,
    required this.currentIndex,
    required this.answers,
  });

  QuestionEntity get currentQuestion => questions[currentIndex];
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == questions.length - 1;
  bool get hasCurrentAnswer => answers.containsKey(currentQuestion.questionId);
  double get progress => (currentIndex + 1) / questions.length;
}

/// All questions answered locally — payload is ready to be submitted **after
/// the oath**. The submit-after-oath rule means `/api/Questions/submit` is
/// no longer called from this cubit.
final class QuestionnaireReadyForOath extends QuestionnaireState {
  final List<Map<String, dynamic>> answersPayload;

  QuestionnaireReadyForOath(this.answersPayload);
}
