import 'package:equatable/equatable.dart';
import 'question_option_entity.dart';

enum QuestionType {
  date,
  height,
  weight,
  select,
  checkbox,
  interests,
  text,
  radio,
  unknown,
}

class QuestionEntity extends Equatable {
  final String questionId;
  final String text;
  final QuestionType type;
  final List<QuestionOptionEntity> options;
  final String categoryName;

  const QuestionEntity({
    required this.questionId,
    required this.text,
    required this.type,
    required this.options,
    this.categoryName = '',
  });

  @override
  List<Object?> get props => [questionId, text, type, options, categoryName];
}
