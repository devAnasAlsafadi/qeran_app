import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Optional label above the field. `null` renders the field with no label.
  final String? labelText;
  final String hintText;
  final Widget prefixIcon;

  const AuthEmailField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.labelText,
    this.hintText = LocaleKeys.auth_email_hint,
    this.prefixIcon = const Icon(
      Icons.email_outlined,
      color: QeranColors.inkMuted,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return QeranTextField(
      controller: controller,
      focusNode: focusNode,
      label: labelText?.t(context),
      hint: hintText.t(context),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefix: prefixIcon,
      validator: Validators.validateEmail,
    );
  }
}
