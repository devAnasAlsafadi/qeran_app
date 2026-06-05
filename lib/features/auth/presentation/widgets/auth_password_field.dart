import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Optional label above the field. `null` renders the field with no label
  /// (e.g. the reset screen, which supplies its own label widget for now).
  final String? labelText;
  final Widget prefixIcon;
  final String hintText;
  final FormFieldValidator<String>? validator;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.labelText,
    this.prefixIcon = const Icon(
      Icons.lock_outline,
      color: QeranColors.inkMuted,
    ),
    this.hintText = LocaleKeys.auth_password_hint,
    this.validator = Validators.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return QeranTextField(
      controller: controller,
      focusNode: focusNode,
      label: labelText?.t(context),
      hint: hintText.t(context),
      // Field owns visibility via the built-in eye — no external notifier.
      obscureText: true,
      showObscureToggle: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      prefix: prefixIcon,
      validator: validator,
    );
  }
}
