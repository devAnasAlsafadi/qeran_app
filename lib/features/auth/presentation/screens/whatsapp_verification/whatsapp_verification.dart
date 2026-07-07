import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import '../../blocs/password_reset/password_reset_bloc.dart';
import '../../blocs/password_reset/password_reset_event.dart';
import '../../blocs/password_reset/password_reset_state.dart';
import '../../blocs/whatsapp/whatsapp_bloc.dart';
import '../../blocs/whatsapp/whatsapp_event.dart';
import '../../blocs/whatsapp/whatsapp_state.dart';
import '../../controllers/otp_controller.dart';
import '../../widgets/auth_hero_scaffold.dart';
import 'widgets/otp_input_row.dart';
import 'widgets/otp_resend_row.dart';
import '../../widgets/auth_title_subtitle.dart';
import 'whatsapp_verification_args.dart';
import 'whatsapp_verification_mode.dart';

class WhatsappVerificationScreen extends StatefulWidget {
  const WhatsappVerificationScreen({super.key});

  @override
  State<WhatsappVerificationScreen> createState() =>
      _WhatsappVerificationScreenState();
}

class _WhatsappVerificationScreenState
    extends State<WhatsappVerificationScreen> {
  late final OtpController _controller;

  String _phoneNumber = '';
  WhatsappVerificationMode _mode = WhatsappVerificationMode.registration;

  @override
  void initState() {
    super.initState();
    _controller = OtpController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WhatsappVerificationArgs) {
      _phoneNumber = args.phoneNumber;
      _mode = args.mode;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildProviders({required Widget child}) {
    if (_mode == WhatsappVerificationMode.passwordReset) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<WhatsappBloc>()),
          BlocProvider(create: (_) => sl<PasswordResetBloc>()),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<WhatsappBloc, WhatsappState>(
              listener: _onWhatsappStateChanged,
            ),
            BlocListener<PasswordResetBloc, PasswordResetState>(
              listener: _onPasswordResetStateChanged,
            ),
          ],
          child: child,
        ),
      );
    }
    return BlocProvider(
      create: (_) => sl<WhatsappBloc>(),
      child: BlocListener<WhatsappBloc, WhatsappState>(
        listener: _onWhatsappStateChanged,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildProviders(
      child: AuthHeroScaffold(
        showBack: true,
        onBack: () => NavigationManager.pop(context),
        children: [
          AuthTitleSubtitle(
            title: LocaleKeys.auth_otp_screen_title.t(context),
          ),
          QeranSpacing.vs16,
          _buildSubtitle(),
          QeranSpacing.vs32,
          OtpInputRow(
            controllers: _controller.otpControllers,
            focusNodes: _controller.otpFocusNodes,
          ),
          QeranSpacing.vs24,
          BlocBuilder<WhatsappBloc, WhatsappState>(
            builder: (context, state) => OtpResendRow(
              onResend: () => _onResend(context),
              isLoading: state is WhatsappLoading,
            ),
          ),
          QeranSpacing.vs48,
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: QeranTypography.body.copyWith(
          color: QeranColors.inkMuted,
        ),
        children: [
          TextSpan(text: LocaleKeys.auth_otp_sent_to_prefix.t(context)),
          TextSpan(
            text: _phoneNumber,
            style: QeranTypography.body.copyWith(
              color: QeranColors.inkStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return BlocBuilder<WhatsappBloc, WhatsappState>(
      builder: (context, whatsappState) {
        if (_mode == WhatsappVerificationMode.passwordReset) {
          return BlocBuilder<PasswordResetBloc, PasswordResetState>(
            builder: (ctx, resetState) {
              final isLoading =
                  whatsappState is WhatsappLoading ||
                  resetState is PasswordResetLoading;
              return QeranButton(
                label: LocaleKeys.common_next.t(ctx),
                variant: QeranButtonVariant.primaryWine,
                loading: isLoading,
                onPressed: isLoading ? null : () => _onNextPressed(ctx),
              );
            },
          );
        }

        final isLoading = whatsappState is WhatsappLoading;
        return QeranButton(
          label: LocaleKeys.common_next.t(context),
          variant: QeranButtonVariant.primaryWine,
          loading: isLoading,
          onPressed: isLoading ? null : () => _onNextPressed(context),
        );
      },
    );
  }

  void _onNextPressed(BuildContext context) {
    if (!_controller.isOtpComplete) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_otp_incomplete.t(context),
        type: SnackBarType.error,
      );
      return;
    }
    final otp = _controller.fullOtp;
    AppLogger.debug('Submitting OTP to API: $otp', tag: 'OTP');
    if (_mode == WhatsappVerificationMode.registration) {
      context.read<WhatsappBloc>().add(
        VerifyOtpRequested(phoneNumber: _phoneNumber, otp: otp),
      );
    } else {
      context.read<PasswordResetBloc>().add(
        VerifyForgotPasswordOtpRequested(phoneNumber: _phoneNumber, code: otp),
      );
    }
  }

  void _onResend(BuildContext context) {
    _controller.clearOtp();
    context.read<WhatsappBloc>().add(ResendOtpRequested(_phoneNumber));
  }

  void _onWhatsappStateChanged(BuildContext context, WhatsappState state) {
    if (state is WhatsappOtpVerified) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_otp_verified_success.t(context),
        type: SnackBarType.success,
      );
      final answered = state.user.hasAnsweredQuestions == true;
      NavigationManager.pushNamedAndRemoveUntil(
        context,
        answered ? RouteNames.homeScreen : RouteNames.genderSelectionScreen,
      );
    } else if (state is WhatsappOtpSent && state.isResend) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_otp_resent_success.t(context),
        type: SnackBarType.success,
      );
    } else if (state is WhatsappFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }

  void _onPasswordResetStateChanged(
    BuildContext context,
    PasswordResetState state,
  ) {
    if (state is PasswordResetOtpVerified) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_otp_verified_success.t(context),
        type: SnackBarType.success,
      );
      NavigationManager.navigateTo(
        context,
        RouteNames.resetPassword,
        arguments: {'phoneNumber': state.phoneNumber, 'otp': state.otp},
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
