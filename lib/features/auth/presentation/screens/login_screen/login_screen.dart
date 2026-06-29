import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../blocs/login/login_bloc.dart';
import '../../blocs/login/login_state.dart';
import '../../blocs/login/login_event.dart';
import '../../widgets/auth_logo_header.dart';
import 'login_controller.dart';
import 'widgets/login_actions.dart';
import 'widgets/login_form.dart';
import 'package:qeran/core/widgets/language_switch_button.dart';

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
      // Builder pushes the context one level below BlocProvider so that
      // `context.read<LoginBloc>()` from the closures captured here can find
      // the bloc. Mirrors the pattern used in RegisterScreen.
      child: Builder(
        builder: (context) {
          return BlocListener<LoginBloc, LoginState>(
            listener: _onStateChanged,
            child: Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: QeranSpacing.s24,
                      vertical: QeranSpacing.s32,
                    ),
                    child: Form(
                      key: _controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: LanguageSwitchButton(
                              variant: LanguageSwitchVariant.dark,
                            ),
                          ),
                          const AuthLogoHeader(),
                          QeranSpacing.vs24,
                          Text(
                            LocaleKeys.auth_login_title.t(context),
                            style: QeranTypography.displaySm.copyWith(
                              fontSize: 35,
                            ),
                          ),
                          QeranSpacing.vs8,
                          Text(
                            LocaleKeys.auth_login_subtitle.t(context),
                            style: QeranTypography.title.copyWith(
                              color: QeranColors.inkMuted,
                            ),
                          ),
                          QeranSpacing.vs24,
                          LoginForm(controller: _controller),
                          QeranSpacing.vs24,
                          LoginActions(
                            onLoginPressed: () => _onLoginPressed(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_login_success.t(context),
        type: SnackBarType.success,
      );
      // Role-first: a matchmaker (role == "Moderator") has NO user
      // onboarding gates. Backend confirms admin roles bypass
      // IsPhoneVerified entirely, so correct credentials land straight
      // on the matchmaker shell — never on phone-verify / questions /
      // oath. This must short-circuit before any user gate below.
      if (state.user.role?.toLowerCase() == 'moderator') {
        NavigationManager.pushNamedAndRemoveUntil(
          context,
          RouteNames.matchmakerHome,
        );
        return;
      }
      if (state.user.isPhoneVerified != true) {
        NavigationManager.navigateTo(context, RouteNames.whatsappInput);
      } else if (state.user.hasAnsweredQuestions != true) {
        NavigationManager.pushNamedAndRemoveUntil(
          context,
          RouteNames.genderSelectionScreen,
        );
      } else {
        NavigationManager.pushNamedAndRemoveUntil(
          context,
          RouteNames.homeScreen,
        );
      }
    } else if (state is LoginFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }
}
