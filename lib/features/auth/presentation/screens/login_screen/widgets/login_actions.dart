import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
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
            final isLoading = state is LoginLoading;
            return CustomButton(
              text: LocaleKeys.auth_login_button.t(context),
              isLoading: isLoading,
              onPressed: isLoading ? null : onLoginPressed,
            );
          },
        ),
        AppDimens.verticalSpace16,
        const OrDivider(),
        AppDimens.verticalSpace16,
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
        const SizedBox(height: AppDimens.p32),
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
