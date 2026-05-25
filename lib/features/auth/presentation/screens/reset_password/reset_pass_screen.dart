import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
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
import 'reset_password_controller.dart';
import '../../widgets/auth_logo_header.dart';
import '../../widgets/auth_back_button.dart';
import '../../widgets/auth_password_field.dart';

class ResetPassScreen extends StatefulWidget {
  const ResetPassScreen({super.key});

  @override
  State<ResetPassScreen> createState() => _ResetPassScreenState();
}

class _ResetPassScreenState extends State<ResetPassScreen> {
  late final ResetPasswordController _controller;

  late String _phoneNumber;
  late String _otp;

  @override
  void initState() {
    super.initState();
    _controller = ResetPasswordController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phoneNumber = args?['phoneNumber'] as String? ?? '';
    _otp = args?['otp'] as String? ?? '';
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
        listener: (ctx, state) => _onStateChanged(ctx, state),
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
                    _buildTitle(),
                    AppDimens.verticalSpace16,
                    _buildSubtitle(),
                    const SizedBox(height: AppDimens.p32),
                    _buildPasswordLabel(),
                    AppDimens.verticalSpace8,
                    _buildPasswordField(),
                    AppDimens.verticalSpace16,
                    _buildConfirmLabel(),
                    AppDimens.verticalSpace8,
                    _buildConfirmField(),
                    const SizedBox(height: AppDimens.p32),
                    _buildResetButton(context, _phoneNumber, _otp),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      LocaleKeys.auth_reset_password_title.t(context),
      style: AppTextStyles.displayLarge,
      textAlign: TextAlign.start,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      LocaleKeys.auth_reset_password_subtitle.t(context),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildPasswordLabel() {
    return Text(
      LocaleKeys.auth_password_label.t(context),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildPasswordField() {
    return AuthPasswordField(
      controller: _controller.passwordController,
      focusNode: _controller.passwordFocus,
      obscurePasswordNotifier: _controller.obscurePasswordNotifier,
      onToggleVisibility: () => _controller.obscurePasswordNotifier.value =
          !_controller.obscurePasswordNotifier.value,
      hintText: LocaleKeys.auth_new_password_hint,
    );
  }

  Widget _buildConfirmLabel() {
    return Text(
      LocaleKeys.auth_confirm_password_label.t(context),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildConfirmField() {
    return AuthPasswordField(
      controller: _controller.confirmPasswordController,
      focusNode: _controller.confirmFocus,
      obscurePasswordNotifier: _controller.obscureConfirmNotifier,
      onToggleVisibility: () => _controller.obscureConfirmNotifier.value =
          !_controller.obscureConfirmNotifier.value,
      hintText: LocaleKeys.auth_confirm_password_hint,
      validator: (v) {
        if (v == null || v.isEmpty) {
          return LocaleKeys.auth_confirm_password_required.t(context);
        }
        if (v != _controller.passwordController.text) {
          return LocaleKeys.auth_passwords_mismatch.t(context);
        }
        return null;
      },
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    String phoneNumber,
    String otp,
  ) {
    return BlocBuilder<PasswordResetBloc, PasswordResetState>(
      builder: (ctx, state) {
        final isLoading = state is PasswordResetLoading;
        return CustomButton(
          text: LocaleKeys.auth_reset_password_button.t(ctx),
          isLoading: isLoading,
          onPressed: isLoading
              ? null
              : () => _onResetPressed(ctx, phoneNumber, otp),
        );
      },
    );
  }

  void _onResetPressed(BuildContext context, String phoneNumber, String otp) {
    if (_controller.validate()) {
      context.read<PasswordResetBloc>().add(
        ResetPasswordRequested(
          phoneNumber: phoneNumber,
          code: otp,
          newPassword: _controller.passwordController.text,
        ),
      );
    }
  }

  void _onStateChanged(BuildContext context, PasswordResetState state) {
    if (state is PasswordResetSuccess) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.auth_reset_password_success.t(context),
        type: SnackBarType.success,
      );
      NavigationManager.pushNamedAndRemoveUntil(
        context,
        RouteNames.loginScreen,
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
