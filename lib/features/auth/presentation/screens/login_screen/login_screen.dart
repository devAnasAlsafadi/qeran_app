import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';

import '../../blocs/login/login_bloc.dart';
import '../../blocs/login/login_event.dart';
import '../../blocs/login/login_state.dart';
import 'login_controller.dart';

import '../../widgets/auth_logo_header.dart';
import '../../widgets/auth_email_field.dart';
import '../../widgets/auth_password_field.dart';
import '../../widgets/auth_footer_link.dart';
import '../../widgets/or_divider.dart';
import '../../widgets/social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginBloc>(),
      child: BlocListener<LoginBloc, LoginState>(
        listener: _onStateChanged,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p24,
                  vertical: AppDimens.p32,
                ),
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthLogoHeader(),
                      AppDimens.verticalSpace24,
                      Text('أهلاً', style: AppTextStyles.displayLarge.copyWith(fontSize: 35)),
                      Text('مرحبا بك', style: AppTextStyles.displayLarge.copyWith(fontSize: 35)),
                      AppDimens.verticalSpace24,
                      AuthEmailField(
                        controller: _controller.emailController,
                        focusNode: _controller.emailFocus,
                        hintText: 'الإيميل',
                        prefixIcon: const Icon(Icons.email, color: AppColors.primary),
                      ),
                      AppDimens.verticalSpace16,
                      AuthPasswordField(
                        controller: _controller.passwordController,
                        focusNode: _controller.passwordFocus,
                        obscurePasswordNotifier: _controller.obscurePasswordNotifier,
                        onToggleVisibility: _controller.togglePasswordVisibility,
                        prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                        iconColor: AppColors.primary,
                      ),
                      _buildForgotPasswordLink(),
                      AppDimens.verticalSpace24,
                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) => CustomButton(
                          text: 'تسجيل دخول',
                          onPressed: state is LoginLoading ? null : () => _onLoginPressed(context),
                        ),
                      ),
                      AppDimens.verticalSpace16,
                      const OrDivider(),
                      AppDimens.verticalSpace16,
                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) => SocialLoginButtons(
                          onGoogleTap: state is LoginLoading
                              ? () {}
                              : () => context.read<LoginBloc>().add(LoginWithGoogleRequested()),
                          onAppleTap: state is LoginLoading
                              ? () {}
                              : () => context.read<LoginBloc>().add(LoginWithAppleRequested()),
                        ),
                      ),
                      const SizedBox(height: AppDimens.p32),
                      AuthFooterLink(
                        promptText: 'لا يوجد لديك حساب ؟',
                        actionText: 'التسجيل',
                        onTap: () => NavigationManager.navigateTo(context, RouteNames.registerScreen),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(

        onPressed: () => NavigationManager.navigateTo(context, RouteNames.forgotPasswordEmail),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          'نسيت كلمة السر',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _onLoginPressed(BuildContext context) {
    if (_controller.validate()) {
      context.read<LoginBloc>().add(
            LoginWithEmailRequested(
              email: _controller.emailController.text.trim(),
              password: _controller.passwordController.text,
            ),
          );
    }
  }



  void _onStateChanged(BuildContext context, LoginState state) {
    if (state is LoginSuccess) {
      if (state.user.isPhoneVerified != true) {
        // Phone not yet verified — go to WhatsApp OTP flow
        NavigationManager.navigateTo(context, RouteNames.whatsappInput);
      } else if (state.user.hasAnsweredQuestions != true) {
        // Phone verified but questionnaire not completed — go to gender selection
        NavigationManager.pushNamedAndRemoveUntil(
          context,
          RouteNames.genderSelectionScreen,
        );
      } else {
        // Fully onboarded — go to home
        NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.homeScreen);
      }
    } else if (state is LoginFailure) {
      AppSnackBar.show(
        context,
        message: state.message,
        type: SnackBarType.error,
      );
    }
  }
}
