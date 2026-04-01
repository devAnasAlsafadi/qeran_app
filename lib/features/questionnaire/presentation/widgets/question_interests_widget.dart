import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
      spacing: AppDimens.p8,
      runSpacing: AppDimens.p8,
      alignment: WrapAlignment.center,
      children: question.options.map((option) {
        final isSelected = selectedOptionIds.contains(option.id);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
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
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p16,
              vertical: AppDimens.p8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: Text(
              option.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
