import '../../domain/entities/question_entity.dart';
import 'question_option_model.dart';

class QuestionModel {
  final String questionId;
  final String text;
  final String type;
  final List<QuestionOptionModel> options;

  const QuestionModel({
    required this.questionId,
    required this.text,
    required this.type,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final optionsList = json['options'] as List<dynamic>? ?? [];
    return QuestionModel(
      questionId: json['questionId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? '',
      options: optionsList
          .map((o) => QuestionOptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  QuestionEntity toEntity() {
    return QuestionEntity(
      questionId: questionId,
      text: text,
      type: _parseType(type),
      options: options.map((o) => o.toEntity()).toList(),
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


