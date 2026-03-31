import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
            padding: const EdgeInsets.symmetric(vertical: AppDimens.p12),
            child: Row(
              children: [
                // Radio circle on the left (RTL makes this appear on the right visually)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
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
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppDimens.p16),
                Expanded(
                  child: Text(
                    option.text,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
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
