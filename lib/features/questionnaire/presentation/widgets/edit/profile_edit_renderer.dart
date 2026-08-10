import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/editable_question.dart';
import '../../../domain/entities/question_entity.dart';
import '../question_interests_widget.dart';
import '../question_text_widget.dart';
import 'edit_dropdown_field.dart';
import 'edit_picker_field.dart';

/// Edit-form counterpart to the sign-up `QuestionRenderer`: dispatches each
/// question type to its EDIT presentation (closed dropdown / drum field /
/// chip grid / bordered text), reusing the shared input widgets underneath.
/// The first-time questionnaire keeps using `QuestionRenderer` unchanged.
class ProfileEditRenderer extends StatelessWidget {
  final EditableQuestion question;
  final dynamic currentAnswer;
  final ValueChanged<dynamic> onAnswerChanged;

  const ProfileEditRenderer({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.select:
      case QuestionType.radio:
        return EditDropdownField(
          question: question,
          selectedId: currentAnswer as String?,
          onChanged: onAnswerChanged,
        );
      case QuestionType.date:
      case QuestionType.height:
      case QuestionType.weight:
        return EditPickerField(
          question: question,
          value: currentAnswer,
          onChanged: onAnswerChanged,
        );
      case QuestionType.checkbox:
      case QuestionType.interests:
        return QuestionInterestsWidget(
          question: question.toQuestionEntity(),
          selectedOptionIds: (currentAnswer as List<String>?) ?? const [],
          onChanged: onAnswerChanged,
        );
      case QuestionType.text:
      case QuestionType.unknown:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionTextWidget(
              currentAnswer: currentAnswer as String?,
              hintText: LocaleKeys.profile_edit_text_hint.t(context),
              onChanged: onAnswerChanged,
            ),
            const SizedBox(height: QeranSpacing.s8),
            const _FieldNote(),
          ],
        );
    }
  }
}

/// The small "نص مؤقت للاستبدال" helper Figma shows under the free-text
/// fields. (Copy is a placeholder to be replaced.)
class _FieldNote extends StatelessWidget {
  const _FieldNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: QeranColors.inkMuted,
        ),
        const SizedBox(width: QeranSpacing.s4),
        Text(
          LocaleKeys.profile_edit_field_note.t(context),
          style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
        ),
      ],
    );
  }
}
