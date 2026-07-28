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
import '../../widgets/auth_hero_scaffold.dart';
import 'login_controller.dart';
import 'widgets/login_actions.dart';
import 'widgets/login_form.dart';

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
            child: AuthHeroScaffold(
              showLanguageSwitch: true,
              children: [
                Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        LocaleKeys.auth_login_title.t(context),
                        style: QeranTypography.title,
                      ),
                      QeranSpacing.vs4,
                      Text(
                        LocaleKeys.auth_login_subtitle.t(context),
                        style: QeranTypography.bodySm.copyWith(
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
              ],
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
      // `tOrRaw`, never `t`: email login now classifies on errorCode and hands
      // up a locale key, but the Firebase social paths still throw pre-worded
      // messages. Translating one of those would print the server's English
      // into an Arabic UI.
      AppSnackBar.show(
        context,
        message: state.message.tOrRaw(context),
        type: SnackBarType.error,
      );
    }
  }
}
