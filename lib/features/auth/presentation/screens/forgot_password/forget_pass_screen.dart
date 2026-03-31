import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import '../../blocs/password_reset/password_reset_bloc.dart';
import '../../blocs/password_reset/password_reset_event.dart';
import '../../blocs/password_reset/password_reset_state.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import '../../controllers/phone_input_controller.dart';
import '../../widgets/auth_logo_header.dart';
import '../../widgets/auth_back_button.dart';
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
                    AuthBackButton(
                      onPressed: () => NavigationManager.pop(context),
                    ),
                    AppDimens.verticalSpace16,
                    const AuthLogoHeader(),
                    AppDimens.verticalSpace24,
                    const AuthTitleSubtitle(
                      title: 'إعادة تعيين كلمة السر',
                      subtitle:
                          'أدخل رقم الهاتف المرتبط بحسابك وسنرسل إليك برسالة نصية تحتوي على تعليمات لإعادة تعيين كلمة مرورك.',
                    ),
                    const SizedBox(height: AppDimens.p32),
                    Text(
                      'رقم الواتسب',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    AppDimens.verticalSpace8,
                    AuthPhoneInput(
                      controller: _controller.phoneController,
                      focusNode: _controller.phoneFocus,
                      countryCodeNotifier: _controller.countryCodeNotifier,
                    ),
                    const SizedBox(height: AppDimens.p32),
                    _buildSendButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return BlocBuilder<PasswordResetBloc, PasswordResetState>(
      builder: (context, state) => CustomButton(
        text: 'إرسال',
        onPressed: state is PasswordResetLoading
            ? null
            : () => _submitPhone(context),
      ),
    );
  }



  void _submitPhone(BuildContext context) {
    final formattedPhone = _controller.validateAndGetFormattedPhone();
    if (formattedPhone != null) {
      context.read<PasswordResetBloc>().add(RequestForgotPasswordOtpRequested(formattedPhone));
    }
  }

  void _onStateChanged(BuildContext context, PasswordResetState state) {
    if (state is PasswordResetOtpSent) {
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
          mode: WhatsappVerificationMode.passwordReset,
        ),
      );
    } else if (state is PasswordResetFailure) {
      AppSnackBar.show(
        context,
        message: state.message,
        type: SnackBarType.error,
      );
    }
  }
}
