import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_text_form_field.dart';
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
        AppTextFormField(
          controller: controller.nameController,
          focusNode: controller.nameFocus,
          hintText: LocaleKeys.auth_name_hint.t(context),
          obscureText: false,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(
            Icons.person_outline,
            color: AppColors.textSecondary,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? LocaleKeys.validators_field_required.t(context)
              : null,
        ),
        AppDimens.verticalSpace16,
        AuthEmailField(
          controller: controller.emailController,
          focusNode: controller.emailFocus,
          hintText: LocaleKeys.auth_email_hint,
        ),
        AppDimens.verticalSpace16,
        AuthPasswordField(
          controller: controller.passwordController,
          focusNode: controller.passwordFocus,
          obscurePasswordNotifier: controller.obscurePasswordNotifier,
          onToggleVisibility: controller.togglePasswordVisibility,
        ),
        RegisterPolicyCheckbox(
          acceptedPolicyNotifier: controller.acceptedPolicyNotifier,
          onToggleAcceptance: controller.togglePolicyAcceptance,
        ),
      ],
    );
  }
}
