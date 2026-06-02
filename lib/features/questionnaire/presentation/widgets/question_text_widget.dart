import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/widgets/app_text_form_field.dart';
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
    return AppTextFormField(
      controller: _controller,
      hintText: LocaleKeys.questionnaire_answer_hint.t(context),
      obscureText: false,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: 5,
      maxLength: 200,
      onChange: widget.onChanged,
    );
  }
}
