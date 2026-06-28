import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../../widgets/auth_email_field.dart';
import '../../../widgets/auth_password_field.dart';
import 'register_policy_checkbox.dart';
import '../register_controller.dart';

class RegisterForm extends StatelessWidget {
  final RegisterController controller;

  const RegisterForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QeranTextField(
          controller: controller.nameController,
          focusNode: controller.nameFocus,
          label: LocaleKeys.auth_name_label.t(context),
          hint: LocaleKeys.auth_name_hint.t(context),
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          prefix: const Icon(
            Icons.person_outline,
            color: QeranColors.inkFaint,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? LocaleKeys.validators_field_required.t(context)
              : null,
        ),
        QeranSpacing.vs16,
        AuthEmailField(
          controller: controller.emailController,
          focusNode: controller.emailFocus,
          labelText: LocaleKeys.auth_email_label,
          hintText: LocaleKeys.auth_email_hint,
        ),
        QeranSpacing.vs16,
        AuthPasswordField(
          controller: controller.passwordController,
          focusNode: controller.passwordFocus,
          labelText: LocaleKeys.auth_password_label,
        ),
        RegisterPolicyCheckbox(
          acceptedPolicyNotifier: controller.acceptedPolicyNotifier,
          onToggleAcceptance: controller.togglePolicyAcceptance,
        ),
      ],
    );
  }
}
