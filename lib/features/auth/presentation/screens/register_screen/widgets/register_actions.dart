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
import '../../../blocs/register/register_bloc.dart';
import '../../../blocs/register/register_state.dart';
import '../../../widgets/auth_footer_link.dart';
import '../../../widgets/or_divider.dart';
import '../../../widgets/social_login_buttons.dart';

class RegisterActions extends StatelessWidget {
  final VoidCallback onRegisterPressed;

  const RegisterActions({super.key, required this.onRegisterPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<RegisterBloc, RegisterState>(
          builder: (context, state) {
            final isLoading = state is RegisterLoading;
            return QeranButton(
              label: LocaleKeys.auth_register_title.t(context),
              variant: QeranButtonVariant.primaryWine,
              loading: isLoading,
              onPressed: isLoading ? null : onRegisterPressed,
            );
          },
        ),
        QeranSpacing.vs16,
        const OrDivider(),
        QeranSpacing.vs16,
        BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) => SocialLoginButtons(
            onGoogleTap: state is LoginLoading
                ? () {}
                : () => context.read<LoginBloc>().add(
                    LoginWithGoogleRequested(),
                  ),
            onAppleTap: state is LoginLoading
                ? () {}
                : () => context.read<LoginBloc>().add(
                    LoginWithAppleRequested(),
                  ),
          ),
        ),
        QeranSpacing.vs24,
        AuthFooterLink(
          promptText: LocaleKeys.auth_have_account.t(context),
          actionText: LocaleKeys.auth_login_button.t(context),
          onTap: () => NavigationManager.navigateAndReplace(
            context,
            RouteNames.loginScreen,
          ),
        ),
      ],
    );
  }
}
