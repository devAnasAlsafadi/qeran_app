import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import '../../../../domain/entities/question_entity.dart';

class QuestionHeader extends StatelessWidget {
  final QuestionEntity question;

  const QuestionHeader({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Text(
      question.text,
      textAlign: TextAlign.start,
      style: QeranTypography.headline,
    );
  }
}
