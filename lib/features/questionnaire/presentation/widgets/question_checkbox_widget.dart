import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import '../../domain/entities/question_entity.dart';

/// Renders a multi-select checkbox list (matching Figma reference).
class QuestionCheckboxWidget extends StatelessWidget {
  final QuestionEntity question;
  final List<String> selectedOptionIds;
  final ValueChanged<List<String>> onChanged;

  const QuestionCheckboxWidget({
    super.key,
    required this.question,
    required this.selectedOptionIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: question.options.map((option) {
        final isSelected = selectedOptionIds.contains(option.id);
        return InkWell(
          onTap: () {
            final updated = List<String>.from(selectedOptionIds);
            if (isSelected) {
              updated.remove(option.id);
            } else {
              updated.add(option.id);
            }
            onChanged(updated);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: QeranRadii.controlR,
                    border: Border.all(
                      color: isSelected
                          ? QeranColors.wine
                          : QeranColors.hairline,
                      width: 2,
                    ),
                    color: isSelected
                        ? QeranColors.wine
                        : QeranColors.creamCanvas,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: QeranColors.paper,
                        )
                      : null,
                ),
                QeranSpacing.hs16,
                Expanded(
                  child: Text(
                    option.text,
                    style: isSelected
                        ? QeranTypography.subtitle
                        : QeranTypography.body,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
