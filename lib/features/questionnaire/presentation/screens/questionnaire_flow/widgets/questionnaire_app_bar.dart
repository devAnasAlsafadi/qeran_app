import 'package:flutter/material.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'category_progress_calculator.dart';
import 'category_step_indicator.dart';

class QuestionnaireAppBar extends StatelessWidget {
  final bool isFirst;
  final List<CategoryStep> steps;
  final int currentQuestionIndex;
  final List<QuestionEntity> questions;
  final Map<String, dynamic> answers;
  final VoidCallback onBack;

  const QuestionnaireAppBar({
    super.key,
    required this.isFirst,
    required this.steps,
    required this.currentQuestionIndex,
    required this.questions,
    required this.answers,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: AppDimens.p8),
        CategoryStepIndicator(
          steps: steps,
          currentQuestionIndex: currentQuestionIndex,
          questions: questions,
          answers: answers,
        ),
      ],
    );
  }
}
