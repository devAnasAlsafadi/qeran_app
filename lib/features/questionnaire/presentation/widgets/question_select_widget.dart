import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import '../../domain/entities/question_entity.dart';

/// Renders a single-select list of radio options (matching Figma reference).
class QuestionSelectWidget extends StatelessWidget {
  final QuestionEntity question;
  final String? selectedOptionId;
  final ValueChanged<String> onChanged;

  const QuestionSelectWidget({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: question.options.map((option) {
        final isSelected = selectedOptionId == option.id;
        return InkWell(
          onTap: () => onChanged(option.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
            child: Row(
              children: [
                // Radio circle on the left (RTL makes this appear on the right visually)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? QeranColors.wine
                          : QeranColors.hairline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: QeranColors.wine,
                            ),
                          ),
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
