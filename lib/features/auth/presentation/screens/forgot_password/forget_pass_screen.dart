import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/di/injection_container.dart';
import '../../blocs/password_reset/password_reset_bloc.dart';
import '../../blocs/password_reset/password_reset_event.dart';
import '../../blocs/password_reset/password_reset_state.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import '../../controllers/phone_input_controller.dart';
import '../../widgets/auth_hero_scaffold.dart';
import '../../widgets/auth_phone_input.dart';
import '../../widgets/auth_title_subtitle.dart';
import '../whatsapp_verification/whatsapp_verification_args.dart';
import '../whatsapp_verification/whatsapp_verification_mode.dart';

class ForgetPassScreen extends StatefulWidget {
  const ForgetPassScreen({super.key});

  @override
  State<ForgetPassScreen> createState() => _ForgetPassScreenState();
}

class _ForgetPassScreenState extends State<ForgetPassScreen> {
  late final PhoneInputController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PhoneInputController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PasswordResetBloc>(),
      child: BlocListener<PasswordResetBloc, PasswordResetState>(
        listener: _onStateChanged,
        child: AuthHeroScaffold(
          showBack: true,
          onBack: () => NavigationManager.pop(context),
          children: [
            Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTitleSubtitle(
                    title: LocaleKeys.auth_forgot_password_title.t(context),
                    subtitle:
                        LocaleKeys.auth_forgot_password_subtitle.t(context),
                  ),
                  QeranSpacing.vs32,
                  Text(
                    LocaleKeys.auth_whatsapp_number_label.t(context),
                    style: QeranTypography.bodySm.copyWith(
                      color: QeranColors.inkBody,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  QeranSpacing.vs8,
                  AuthPhoneInput(
                    controller: _controller.phoneController,
                    focusNode: _controller.phoneFocus,
                    countryCodeNotifier: _controller.countryCodeNotifier,
                  ),
                  QeranSpacing.vs32,
                  _buildSendButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return BlocBuilder<PasswordResetBloc, PasswordResetState>(
      builder: (context, state) {
        final isLoading = state is PasswordResetLoading;
        return QeranButton(
          label: LocaleKeys.common_send.t(context),
          variant: QeranButtonVariant.primaryWine,
          loading: isLoading,
          onPressed: isLoading ? null : () => _submitPhone(context),
        );
      },
    );
  }

  void _submitPhone(BuildContext context) {
    final formattedPhone = _controller.validateAndGetFormattedPhone();
    if (formattedPhone != null) {
      context.read<PasswordResetBloc>().add(
        RequestForgotPasswordOtpRequested(formattedPhone),
      );
    }
  }

  void _onStateChanged(BuildContext context, PasswordResetState state) {
    if (state is PasswordResetOtpSent) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_otp_sent_success.t(context),
        type: SnackBarType.success,
      );
      NavigationManager.navigateTo(
        context,
        RouteNames.whatsappVerification,
        arguments: WhatsappVerificationArgs(
          phoneNumber: state.phoneNumber,
          mode: WhatsappVerificationMode.passwordReset,
        ),
      );
    } else if (state is PasswordResetFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }
}
