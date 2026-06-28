import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'category_progress_calculator.dart';
import 'category_step_indicator.dart';

class QuestionnaireAppBar extends StatelessWidget {
  final bool isFirst;
  final String categoryName;
  final List<CategoryStep> steps;
  final int currentQuestionIndex;
  final List<QuestionEntity> questions;
  final Map<String, dynamic> answers;
  final VoidCallback onBack;

  const QuestionnaireAppBar({
    super.key,
    required this.isFirst,
    required this.categoryName,
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
        Row(
          children: [
            // Nav sits at the start edge (right in Arabic/RTL, left in LTR).
            _NavBackButton(onBack: onBack),
            Expanded(
              child: Text(
                categoryName,
                textAlign: TextAlign.center,
                style: QeranTypography.title,
              ),
            ),
            // Mirror the nav button's footprint so the title stays centered.
            const SizedBox(width: QeranSpacing.s48),
          ],
        ),
        QeranSpacing.vs12,
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

/// Back affordance whose arrow follows the ambient text direction: it points
/// to the right in RTL (Arabic) and flips to the left in LTR — never hardcoded.
class _NavBackButton extends StatelessWidget {
  const _NavBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    return IconButton(
      icon: Icon(
        Icons.chevron_left_rounded   ,
        size: 20,
        color: QeranColors.wine,
      ),
      onPressed: onBack,
    );
  }
}
