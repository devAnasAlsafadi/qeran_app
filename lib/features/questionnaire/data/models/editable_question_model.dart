import '../../domain/entities/editable_question.dart';
import '../../domain/entities/question_entity.dart';
import 'question_option_model.dart';

class EditableQuestionModel {
  final String questionId;
  final String text;
  final String type;
  final bool isRequired;
  final List<QuestionOptionModel> options;
  final List<String> selectedOptionIds;
  final String? textAnswer;

  const EditableQuestionModel({
    required this.questionId,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.options,
    required this.selectedOptionIds,
    required this.textAnswer,
  });

  factory EditableQuestionModel.fromJson(Map<String, dynamic> json) {
    final optionsList = json['options'] as List<dynamic>? ?? [];
    final selected = json['selectedOptionIds'] as List<dynamic>? ?? [];
    return EditableQuestionModel(
      questionId: json['questionId']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? false,
      options: optionsList
          .map((o) => QuestionOptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      selectedOptionIds: selected.map((e) => e.toString()).toList(),
      textAnswer: json['textAnswer'] as String?,
    );
  }

  EditableQuestion toEntity() {
    return EditableQuestion(
      questionId: questionId,
      text: text,
      type: _parseType(type),
      isRequired: isRequired,
      options: options.map((o) => o.toEntity()).toList(),
      selectedOptionIds: selectedOptionIds,
      textAnswer: textAnswer,
    );
  }

  QuestionType _parseType(String raw) {
    return switch (raw.toLowerCase()) {
      'date' => QuestionType.date,
      'height' => QuestionType.height,
      'weight' => QuestionType.weight,
      'select' => QuestionType.select,
      'checkbox' => QuestionType.checkbox,
      'interests' => QuestionType.interests,
      'text' => QuestionType.text,
      'radio' => QuestionType.radio,
      _ => QuestionType.unknown,
    };
  }
}
