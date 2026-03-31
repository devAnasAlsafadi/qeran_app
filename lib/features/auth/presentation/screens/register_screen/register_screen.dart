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
import 'package:qeran/core/widgets/app_text_form_field.dart';

import '../../blocs/login/login_bloc.dart';
import '../../blocs/login/login_event.dart';
import '../../blocs/login/login_state.dart';
import '../../blocs/register/register_bloc.dart';
import '../../blocs/register/register_event.dart';
import '../../blocs/register/register_state.dart';
import 'register_controller.dart';

import '../../widgets/auth_logo_header.dart';
import '../../widgets/auth_back_button.dart';
import '../../widgets/auth_email_field.dart';
import '../../widgets/auth_password_field.dart';
import '../../widgets/auth_footer_link.dart';
import '../../widgets/or_divider.dart';
import '../../widgets/social_login_buttons.dart';
import '../../widgets/register_policy_checkbox.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RegisterBloc>()),
        BlocProvider(create: (_) => sl<LoginBloc>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<RegisterBloc, RegisterState>(listener: _onRegisterStateChanged),
          BlocListener<LoginBloc, LoginState>(listener: _onSocialLoginStateChanged),
        ],
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppDimens.p24,
                    end: AppDimens.p24,
                    top: AppDimens.p16,
                  ),
                  child: AuthBackButton(onPressed: () => NavigationManager.pop(context)),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p24,
                        vertical: AppDimens.p16,
                      ),
                      child: Form(
                        key: _controller.formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthLogoHeader(),
                            AppDimens.verticalSpace16,
                            Text(
                              'إنشاء حساب',
                              style: AppTextStyles.displayLarge,
                              textAlign: TextAlign.right,
                            ),
                            AppDimens.verticalSpace24,
                            AppTextFormField(
                              controller: _controller.nameController,
                              focusNode: _controller.nameFocus,
                              hintText: 'الاسم',
                              obscureText: false,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                            ),
                            AppDimens.verticalSpace16,

                            AuthEmailField(
                              controller: _controller.emailController,
                              focusNode: _controller.emailFocus,
                              hintText: 'الايميل',
                            ),
                            AppDimens.verticalSpace16,

                            AuthPasswordField(
                              controller: _controller.passwordController,
                              focusNode: _controller.passwordFocus,
                              obscurePasswordNotifier: _controller.obscurePasswordNotifier,
                              onToggleVisibility: _controller.togglePasswordVisibility,
                            ),

                            RegisterPolicyCheckbox(
                              acceptedPolicyNotifier: _controller.acceptedPolicyNotifier,
                              onToggleAcceptance: _controller.togglePolicyAcceptance,
                            ),
                            AppDimens.verticalSpace16,

                            BlocBuilder<RegisterBloc, RegisterState>(
                              builder: (context, state) => CustomButton(
                                text: 'إنشاء حساب',
                                onPressed: state is RegisterLoading ? null : () => _onRegisterPressed(context),
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
                            AppDimens.verticalSpace24,

                            AuthFooterLink(
                              promptText: 'لدي حساب بالفعل ؟',
                              actionText: 'تسجيل دخول',
                              onTap: () => NavigationManager.navigateAndReplace(context, RouteNames.loginScreen),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _onRegisterPressed(BuildContext context) {
    if (!_controller.acceptedPolicy) {
      AppSnackBar.show(context, message: 'يجب الموافقة على سياسات الخصوصية', type: SnackBarType.error);
      return;
    }
    if (_controller.validate()) {
      context.read<RegisterBloc>().add(RegisterRequested(
            name: _controller.nameController.text.trim(),
            email: _controller.emailController.text.trim(),
            password: _controller.passwordController.text,
          ));
    }
  }


  void _onRegisterStateChanged(BuildContext context, RegisterState state) {
    if (state is RegisterSuccess) {
      AppSnackBar.show(
        context,
        message: 'تم إنشاء الحساب بنجاح، يرجى إضافة رقم الهاتف',
        type: SnackBarType.success,
      );
      NavigationManager.navigateTo(context, RouteNames.whatsappInput);
    } else if (state is RegisterFailure) {
      AppSnackBar.show(context, message: state.message, type: SnackBarType.error);
    }
  }

  void _onSocialLoginStateChanged(BuildContext context, LoginState state) {
    if (state is LoginSuccess) {
      NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.homeScreen);
    } else if (state is LoginFailure) {
      AppSnackBar.show(context, message: state.message, type: SnackBarType.error);
    }
  }
}
