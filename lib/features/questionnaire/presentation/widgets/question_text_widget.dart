import 'package:flutter/material.dart';
import 'package:qeran/core/widgets/app_text_form_field.dart';
import 'package:qeran/core/theme/app_color.dart';

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
      hintText: 'الإجابة',
      obscureText: false,
      keyboardType: TextInputType.text,
      fillColor: AppColors.fieldBackground,
      onChange: widget.onChanged,
    );
  }
}
