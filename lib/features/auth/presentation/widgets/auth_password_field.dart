import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/generated/locale_keys.g.dart';

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
      color: QeranColors.inkMuted,
    ),
    this.iconColor = QeranColors.inkMuted,
    this.hintText = LocaleKeys.auth_password_hint,
    this.validator = Validators.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: obscurePasswordNotifier,
      builder: (context, obscurePassword, child) {
        return QeranTextField(
          controller: controller,
          focusNode: focusNode,
          hint: hintText.t(context),
          obscureText: obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          prefix: prefixIcon,
          // External notifier still drives visibility for now; the built-in
          // showObscureToggle is adopted in sub-step c with the screens.
          suffix: IconButton(
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
