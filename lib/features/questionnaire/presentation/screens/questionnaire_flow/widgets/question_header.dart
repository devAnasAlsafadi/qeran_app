import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import '../../../../domain/entities/question_entity.dart';

class QuestionHeader extends StatelessWidget {
  final QuestionEntity question;

  const QuestionHeader({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.categoryName.isNotEmpty) ...[
          Text(
            question.categoryName,
            textAlign: TextAlign.center,
            style: QeranTypography.bodySm,
          ),
          QeranSpacing.vs8,
        ],
        Text(
          question.text,
          textAlign: TextAlign.center,
          style: QeranTypography.headline,
        ),
      ],
    );
  }
}
