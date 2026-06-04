import 'package:equatable/equatable.dart';

import 'question_entity.dart';
import 'question_option_entity.dart';

/// One question on the profile-edit form (`GET /api/questions/edit-form`):
/// the question schema plus MY current answer. Free-text types
/// (text/date/height/weight) carry [textAnswer]; option types
/// (select/radio/checkbox/interests) carry [selectedOptionIds].
class EditableQuestion extends Equatable {
  final String questionId;
  final String text;
  final QuestionType type;
  final bool isRequired;
  final List<QuestionOptionEntity> options;
  final List<String> selectedOptionIds;
  final String? textAnswer;

  const EditableQuestion({
    required this.questionId,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.options,
    required this.selectedOptionIds,
    required this.textAnswer,
  });

  /// Schema view consumed by the shared `QuestionRenderer` (the edit form
  /// reuses the questionnaire's per-type input widgets). The current answer
  /// is supplied separately by the cubit, so it is not carried here.
  QuestionEntity toQuestionEntity() {
    return QuestionEntity(
      questionId: questionId,
      text: text,
      type: type,
      options: options,
    );
  }

  @override
  List<Object?> get props => [
        questionId,
        text,
        type,
        isRequired,
        options,
        selectedOptionIds,
        textAnswer,
      ];
}
