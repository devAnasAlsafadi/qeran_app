import 'package:flutter/material.dart';
import '../../domain/entities/question_entity.dart';
import 'question_checkbox_widget.dart';
import 'question_date_widget.dart';
import 'question_height_widget.dart';
import 'question_select_widget.dart';
import 'question_weight_widget.dart';
import 'question_interests_widget.dart';
import 'question_text_widget.dart';

/// Factory widget that dispatches to the correct answer widget
/// based on [QuestionType].
class QuestionRenderer extends StatelessWidget {
  final QuestionEntity question;
  final dynamic currentAnswer;
  final ValueChanged<dynamic> onAnswerChanged;

  const QuestionRenderer({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return switch (question.type) {
      QuestionType.select || QuestionType.radio => QuestionSelectWidget(
          question: question,
          selectedOptionId: currentAnswer as String?,
          onChanged: onAnswerChanged,
        ),
      QuestionType.checkbox => QuestionCheckboxWidget(
          question: question,
          selectedOptionIds: (currentAnswer as List<String>?) ?? [],
          onChanged: onAnswerChanged,
        ),
      QuestionType.interests => QuestionInterestsWidget(
          question: question,
          selectedOptionIds: (currentAnswer as List<String>?) ?? [],
          onChanged: onAnswerChanged,
        ),
      QuestionType.text => QuestionTextWidget(
          currentAnswer: currentAnswer as String?,
          onChanged: onAnswerChanged,
        ),
      QuestionType.date => QuestionDateWidget(
          selectedDate: currentAnswer as DateTime?,
          onChanged: onAnswerChanged,
        ),
      QuestionType.height => QuestionHeightWidget(
          selectedHeight: currentAnswer as int?,
          onChanged: onAnswerChanged,
        ),
      QuestionType.weight => QuestionWeightWidget(
          selectedWeight: currentAnswer as int?,
          onChanged: onAnswerChanged,
        ),
      QuestionType.unknown => const SizedBox.shrink(),
    };
  }
}
