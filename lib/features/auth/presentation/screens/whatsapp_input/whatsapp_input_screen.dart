import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/widgets/exit_app_dialog.dart';
import 'package:qeran/core/widgets/onboarding_pop_scope.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/utils/phone_formatter.dart';
import '../../blocs/whatsapp/whatsapp_bloc.dart';
import '../../blocs/whatsapp/whatsapp_event.dart';
import '../../blocs/whatsapp/whatsapp_state.dart';
import '../../controllers/phone_input_controller.dart';
import '../../widgets/auth_logo_header.dart';
import '../../widgets/auth_back_button.dart';
import '../../widgets/auth_phone_input.dart';
import '../../widgets/auth_title_subtitle.dart';
import '../whatsapp_verification/whatsapp_verification_args.dart';
import '../whatsapp_verification/whatsapp_verification_mode.dart';

class WhatsappInputScreen extends StatefulWidget {
  const WhatsappInputScreen({super.key});

  @override
  State<WhatsappInputScreen> createState() => _WhatsappInputScreenState();
}

class _WhatsappInputScreenState extends State<WhatsappInputScreen> {
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
      create: (_) => sl<WhatsappBloc>(),
      child: BlocListener<WhatsappBloc, WhatsappState>(
        listener: _onStateChanged,
        child: OnboardingPopScope(
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s24,
                  vertical: QeranSpacing.s16,
                ),
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthBackButton(
                        onPressed: () => ExitAppDialog.show(context),
                      ),
                      QeranSpacing.vs16,
                      const AuthLogoHeader(),
                      QeranSpacing.vs24,
                      AuthTitleSubtitle(
                        title: LocaleKeys.auth_whatsapp_title.t(context),
                        subtitle: LocaleKeys.auth_whatsapp_subtitle.t(context),
                      ),
                      QeranSpacing.vs32,
                      AuthPhoneInput(
                        controller: _controller.phoneController,
                        focusNode: _controller.phoneFocus,
                        countryCodeNotifier: _controller.countryCodeNotifier,
                      ),
                      QeranSpacing.vs48,
                      BlocBuilder<WhatsappBloc, WhatsappState>(
                        builder: (context, state) {
                          final isLoading = state is WhatsappLoading;
                          return QeranButton(
                            label: LocaleKeys.common_send.t(context),
                            variant: QeranButtonVariant.primaryWine,
                            loading: isLoading,
                            onPressed: isLoading
                                ? null
                                : () => _onSendPressed(context),
                          );
                        },
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

  void _onSendPressed(BuildContext context) {
    if (_controller.validate()) {
      final formattedPhone = PhoneFormatter.toApiFormat(
        _controller.selectedCountryCode,
        _controller.phoneController.text,
      );
      context.read<WhatsappBloc>().add(SendOtpRequested(formattedPhone));
    }
  }

  void _onStateChanged(BuildContext context, WhatsappState state) {
    if (state is WhatsappOtpSent) {
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
          mode: WhatsappVerificationMode.registration,
        ),
      );
    } else if (state is WhatsappFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }
}
