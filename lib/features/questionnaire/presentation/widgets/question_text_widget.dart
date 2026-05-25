import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Renders a long-form text answer. All `QuestionType.text` questions in the
/// product are bio/about fields, so this widget is always multiline — no
/// per-question detection.
class QuestionTextWidget extends StatefulWidget {
  final String? currentAnswer;
  final ValueChanged<String> onChanged;

  const QuestionTextWidget({
    super.key,
    required this.currentAnswer,
    required this.onChanged,
  });

  @override
  State<QuestionTextWidget> createState() => _QuestionTextWidgetState();
}

class _QuestionTextWidgetState extends State<QuestionTextWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAnswer ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      minLines: 5,
      maxLines: 8,
      maxLength: 200,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: LocaleKeys.questionnaire_answer_hint.t(context),
        hintStyle: const TextStyle(color: AppColors.grey),
        fillColor: AppColors.fieldBackground,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p16,
          vertical: AppDimens.p16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadius16,
          borderSide: const BorderSide(color: AppColors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadius8,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
