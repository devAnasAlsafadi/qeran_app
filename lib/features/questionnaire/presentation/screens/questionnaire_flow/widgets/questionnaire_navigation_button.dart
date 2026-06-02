import 'package:flutter/material.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class QuestionnaireNavigationButton extends StatelessWidget {
  final bool isLast;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const QuestionnaireNavigationButton({
    super.key,
    required this.isLast,
    required this.isLoading,
    required this.enabled,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: isLast
          ? LocaleKeys.questionnaire_finish_button.t(context)
          : LocaleKeys.common_next.t(context),
      isLoading: isLoading,
      onPressed: enabled ? (isLast ? onFinish : onNext) : null,
    );
  }
}
