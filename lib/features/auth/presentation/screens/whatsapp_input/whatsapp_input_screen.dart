import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
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
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p24,
                vertical: AppDimens.p16,
              ),
              child: Form(
                key: _controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthBackButton(onPressed: () => NavigationManager.pop(context)),
                    AppDimens.verticalSpace16,
                    const AuthLogoHeader(),
                    AppDimens.verticalSpace24,
                    const AuthTitleSubtitle(
                      title: 'ما هو رقم هاتفك ؟',
                      subtitle: 'أدخل رقم هاتفك',
                    ),
                    const SizedBox(height: AppDimens.p32),
                    AuthPhoneInput(
                      controller: _controller.phoneController,
                      focusNode: _controller.phoneFocus,
                      countryCodeNotifier: _controller.countryCodeNotifier,
                    ),
                    const SizedBox(height: AppDimens.p48),
                    BlocBuilder<WhatsappBloc, WhatsappState>(
                      builder: (context, state) => CustomButton(
                        text: 'إرسال',
                        onPressed: state is WhatsappLoading ? null : () => _onSendPressed(context),
                      ),
                    ),
                  ],
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
        message: 'تم إرسال كود التحقق إلى رقم الواتساب الخاص بك',
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
      AppSnackBar.show(context, message: state.message, type: SnackBarType.error);
    }
  }
}
