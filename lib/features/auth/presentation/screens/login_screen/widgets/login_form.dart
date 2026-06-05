import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../../widgets/auth_email_field.dart';
import '../../../widgets/auth_password_field.dart';
import '../login_controller.dart';

class LoginForm extends StatelessWidget {
  final LoginController controller;

  const LoginForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthEmailField(
          controller: controller.emailController,
          focusNode: controller.emailFocus,
          labelText: LocaleKeys.auth_email_label,
          hintText: LocaleKeys.auth_email_hint,
          prefixIcon: const Icon(Icons.email, color: QeranColors.inkFaint),
        ),
        AppDimens.verticalSpace16,
        AuthPasswordField(
          controller: controller.passwordController,
          focusNode: controller.passwordFocus,
          labelText: LocaleKeys.auth_password_label,
          prefixIcon: const Icon(Icons.lock, color: QeranColors.inkFaint),
        ),
        _buildForgotPasswordLink(context),
      ],
    );
  }

  Widget _buildForgotPasswordLink(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: () => NavigationManager.navigateTo(
          context,
          RouteNames.forgotPasswordEmail,
        ),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          LocaleKeys.auth_forgot_password.t(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
