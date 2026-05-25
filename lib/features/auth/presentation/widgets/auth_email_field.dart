import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/core/widgets/app_text_form_field.dart';

class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final Widget prefixIcon;

  const AuthEmailField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = LocaleKeys.auth_email_hint,
    this.prefixIcon = const Icon(
      Icons.email_outlined,
      color: AppColors.textSecondary,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText.t(context),
      obscureText: false,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: prefixIcon,
      validator: Validators.validateEmail,
    );
  }
}
