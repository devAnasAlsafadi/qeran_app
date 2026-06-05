import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
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
import 'reset_password_controller.dart';
import '../../widgets/auth_logo_header.dart';
import '../../widgets/auth_back_button.dart';
import '../../widgets/auth_password_field.dart';
import '../../widgets/auth_title_subtitle.dart';

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
                horizontal: QeranSpacing.s24,
                vertical: QeranSpacing.s16,
              ),
              child: Form(
                key: _controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthBackButton(
                      onPressed: () => NavigationManager.pop(context),
                    ),
                    QeranSpacing.vs16,
                    const AuthLogoHeader(),
                    QeranSpacing.vs24,
                    AuthTitleSubtitle(
                      title: LocaleKeys.auth_reset_password_title.t(context),
                      subtitle:
                          LocaleKeys.auth_reset_password_subtitle.t(context),
                    ),
                    QeranSpacing.vs32,
                    _buildPasswordField(),
                    QeranSpacing.vs16,
                    _buildConfirmField(),
                    QeranSpacing.vs32,
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

  Widget _buildPasswordField() {
    return AuthPasswordField(
      controller: _controller.passwordController,
      focusNode: _controller.passwordFocus,
      labelText: LocaleKeys.auth_password_label,
      hintText: LocaleKeys.auth_new_password_hint,
    );
  }

  Widget _buildConfirmField() {
    return AuthPasswordField(
      controller: _controller.confirmPasswordController,
      focusNode: _controller.confirmFocus,
      labelText: LocaleKeys.auth_confirm_password_label,
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
        return QeranButton(
          label: LocaleKeys.auth_reset_password_button.t(ctx),
          variant: QeranButtonVariant.primaryWine,
          loading: isLoading,
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
