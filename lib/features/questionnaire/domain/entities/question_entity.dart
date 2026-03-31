import 'package:equatable/equatable.dart';
import 'question_option_entity.dart';

enum QuestionType { date, height, weight, select, checkbox, unknown }

class QuestionEntity extends Equatable {
  final String questionId;
  final String text;
  final QuestionType type;
  final List<QuestionOptionEntity> options;

  const QuestionEntity({
    required this.questionId,
    required this.text,
    required this.type,
    required this.options,
  });

  /// A question is renderable only when it can be meaningfully answered.
  /// - [QuestionType.select] / [QuestionType.checkbox]: require at least one option.
  /// - [QuestionType.date] / [QuestionType.height] / [QuestionType.weight]: always renderable.
  /// - [QuestionType.unknown]: never renderable.
  bool get isRenderable => switch (type) {
        QuestionType.select || QuestionType.checkbox => options.isNotEmpty,
        QuestionType.date ||
        QuestionType.height ||
        QuestionType.weight =>
          true,
        QuestionType.unknown => false,
      };

  @override
  List<Object?> get props => [questionId, text, type, options];
}
