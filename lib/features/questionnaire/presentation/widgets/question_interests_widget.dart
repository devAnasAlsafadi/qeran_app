import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import '../../domain/entities/question_entity.dart';

/// Renders a multi-select chip-style list for interests.
class QuestionInterestsWidget extends StatelessWidget {
  final QuestionEntity question;
  final List<String> selectedOptionIds;
  final ValueChanged<List<String>> onChanged;

  const QuestionInterestsWidget({
    super.key,
    required this.question,
    required this.selectedOptionIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s8,
      alignment: WrapAlignment.center,
      children: question.options.map((option) {
        final isSelected = selectedOptionIds.contains(option.id);
        return InkWell(
          borderRadius: QeranRadii.pill,
          onTap: () {
            final updated = List<String>.from(selectedOptionIds);
            if (isSelected) {
              updated.remove(option.id);
            } else {
              updated.add(option.id);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: QeranMotion.standard,
            curve: QeranCurves.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s16,
              vertical: QeranSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? QeranColors.wine : QeranColors.creamCanvas,
              borderRadius: QeranRadii.pill,
              border: Border.all(
                color: isSelected ? QeranColors.wine : QeranColors.hairline,
                width: 1,
              ),
            ),
            child: Text(
              option.text,
              style: QeranTypography.label.copyWith(
                color: isSelected ? QeranColors.paper : QeranColors.inkStrong,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
