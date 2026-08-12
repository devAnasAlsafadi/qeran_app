import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../../blocs/login/login_bloc.dart';
import '../../../blocs/login/login_event.dart';
import '../../../blocs/login/login_state.dart';
import '../../../widgets/auth_footer_link.dart';
import '../../../widgets/or_divider.dart';
import '../../../widgets/social_login_buttons.dart';

class LoginActions extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const LoginActions({super.key, required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) {
            final busy = state is LoginLoading;
            return QeranButton(
              label: LocaleKeys.auth_login_button.t(context),
              variant: QeranButtonVariant.primaryWine,
              // Only the email path spins this button; a Google sign-in
              // leaves it idle.
              loading: state is LoginLoading && state.method == AuthMethod.email,
              onPressed: busy ? null : onLoginPressed,
            );
          },
        ),
        QeranSpacing.vs12,
        const OrDivider(),
        QeranSpacing.vs12,
        BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) {
            final busy = state is LoginLoading;
            return SocialLoginButtons(
              busy: busy,
              googleLoading:
                  state is LoginLoading && state.method == AuthMethod.google,
              appleLoading:
                  state is LoginLoading && state.method == AuthMethod.apple,
              onGoogleTap: () =>
                  context.read<LoginBloc>().add(LoginWithGoogleRequested()),
              onAppleTap: () =>
                  context.read<LoginBloc>().add(LoginWithAppleRequested()),
            );
          },
        ),
        QeranSpacing.vs24,
        AuthFooterLink(
          promptText: LocaleKeys.auth_no_account.t(context),
          actionText: LocaleKeys.auth_register_link.t(context),
          onTap: () => NavigationManager.navigateTo(
            context,
            RouteNames.registerScreen,
          ),
        ),
      ],
    );
  }
}
