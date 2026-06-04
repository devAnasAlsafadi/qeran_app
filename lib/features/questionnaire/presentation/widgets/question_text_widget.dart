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

  /// Optional placeholder override. Defaults to the questionnaire hint so the
  /// first-time sign-up flow (which passes nothing) renders unchanged; the
  /// profile-edit form passes its own Figma hint.
  final String? hintText;

  /// Character cap (shows the built-in counter). Defaults to 200 so sign-up
  /// is unchanged; the profile-edit form passes `null` (the backend enforces
  /// no length, so no counter there).
  final int? maxLength;

  const QuestionTextWidget({
    super.key,
    required this.currentAnswer,
    required this.onChanged,
    this.hintText,
    this.maxLength = 200,
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
      hintText: widget.hintText ?? LocaleKeys.questionnaire_answer_hint.t(context),
      obscureText: false,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: 5,
      maxLength: widget.maxLength,
      onChange: widget.onChanged,
    );
  }
}
