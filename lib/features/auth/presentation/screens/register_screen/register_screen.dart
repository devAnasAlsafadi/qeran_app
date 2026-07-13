import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../blocs/login/login_bloc.dart';
import '../../blocs/login/login_state.dart';
import '../../blocs/register/register_bloc.dart';
import '../../blocs/register/register_event.dart';
import '../../blocs/register/register_state.dart';
import '../../widgets/auth_hero_scaffold.dart';
import 'register_controller.dart';
import 'widgets/register_actions.dart';
import 'widgets/register_form.dart';

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
      child: Builder(
        builder: (context) {
          return MultiBlocListener(
        listeners: [
          BlocListener<RegisterBloc, RegisterState>(
            listener: _onRegisterStateChanged,
          ),
          BlocListener<LoginBloc, LoginState>(
            listener: _onSocialLoginStateChanged,
          ),
        ],
        child: AuthHeroScaffold(
          showBack: true,
          onBack: () => NavigationManager.pop(context),
          children: [
            Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    LocaleKeys.auth_register_title.t(context),
                    style: QeranTypography.title,
                  ),
                  QeranSpacing.vs24,
                  RegisterForm(controller: _controller),
                  QeranSpacing.vs16,
                  RegisterActions(
                    onRegisterPressed: () => _onRegisterPressed(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }

  void _onRegisterPressed(BuildContext context) {
    if (!_controller.acceptedPolicy) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_policy_not_accepted.t(context),
        type: SnackBarType.error,
      );
      return;
    }





    if (_controller.validate()) {
      context.read<RegisterBloc>().add(
        RegisterRequested(
          name: _controller.nameController.text.trim(),
          email: _controller.emailController.text.trim(),
          password: _controller.passwordController.text,
          referralCode: _controller.referralCodeController.text.trim(),
        ),
      );
    }
  }

  void _onRegisterStateChanged(BuildContext context, RegisterState state) {
    if (state is RegisterSuccess) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_register_success.t(context),
        type: SnackBarType.success,
      );
      NavigationManager.navigateTo(context, RouteNames.whatsappInput);
    } else if (state is RegisterFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }

  void _onSocialLoginStateChanged(BuildContext context, LoginState state) {
    if (state is LoginSuccess) {
      NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.homeScreen);
    } else if (state is LoginFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }
}
