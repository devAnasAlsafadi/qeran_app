import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/core/widgets/app_text_form_field.dart';

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueNotifier<bool> obscurePasswordNotifier;
  final VoidCallback onToggleVisibility;
  final Widget prefixIcon;
  final Color iconColor;
  final String hintText;
  final FormFieldValidator<String>? validator;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.obscurePasswordNotifier,
    required this.onToggleVisibility,
    this.prefixIcon = const Icon(
      Icons.lock_outline,
      color: AppColors.textSecondary,
    ),
    this.iconColor = AppColors.textSecondary,
    this.hintText = LocaleKeys.auth_password_hint,
    this.validator = Validators.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: obscurePasswordNotifier,
      builder: (context, obscurePassword, child) {
        return AppTextFormField(
          controller: controller,
          focusNode: focusNode,
          hintText: hintText.t(context),
          obscureText: obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          prefixIcon: prefixIcon,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: iconColor,
            ),
            onPressed: onToggleVisibility,
          ),
          validator: validator,
        );
      },
    );
  }
}
