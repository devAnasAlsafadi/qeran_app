import '../../domain/entities/question_option_entity.dart';

class QuestionOptionModel {
  final String id;
  final String text;

  const QuestionOptionModel({required this.id, required this.text});

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  QuestionOptionEntity toEntity() {
    return QuestionOptionEntity(id: id, text: text);
  }
}
