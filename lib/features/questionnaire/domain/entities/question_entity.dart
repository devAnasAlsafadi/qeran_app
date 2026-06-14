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

  /// Whether this question can actually be answered by the user.
  ///
  /// Option-driven types (select / radio / checkbox / interests) need at
  /// least one option to be selectable — an empty options array is a backend
  /// data gap that would render nothing and trap the user (Next never
  /// enables). All other types (text / date / height / weight / unknown)
  /// always render an input, so they are always answerable.
  bool get isAnswerable => switch (type) {
        QuestionType.select ||
        QuestionType.radio ||
        QuestionType.checkbox ||
        QuestionType.interests =>
          options.isNotEmpty,
        QuestionType.text ||
        QuestionType.date ||
        QuestionType.height ||
        QuestionType.weight ||
        QuestionType.unknown =>
          true,
      };

  @override
  List<Object?> get props => [questionId, text, type, options, categoryName];
}
