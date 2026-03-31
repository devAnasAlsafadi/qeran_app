import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/widgets/app_text_form_field.dart';

class RegisterNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const RegisterNameField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: controller,
      focusNode: focusNode,
      hintText: 'الاسم',
      obscureText: false,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
    );
  }
}
