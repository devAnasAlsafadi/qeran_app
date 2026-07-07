import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_sheet_handle.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/change_password/change_password_cubit.dart';
import '../blocs/change_password/change_password_state.dart';

/// Opens the change-password bottom sheet (self-provides its cubit). Any
/// signed-in user can change their password via the shared auth endpoint.
Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => BlocProvider(
      create: (_) => sl<ChangePasswordCubit>(),
      child: const _ChangePasswordSheet(),
    ),
  );
}

/// Current + new + confirm password, all obscured with the built-in eye. The
/// form enforces the app's standard password rules (≥8 + regex, via
/// [Validators.validatePassword]), confirm-match, and new≠current. A wrong
/// current password surfaces inline under the current-password field.
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  String? _currentServerError;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _clearServerError(String _) {
    if (_currentServerError != null) {
      setState(() => _currentServerError = null);
    }
  }

  void _submit(ChangePasswordCubit cubit) {
    setState(() => _currentServerError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    cubit.submit(
      currentPassword: _current.text,
      newPassword: _newPassword.text,
      confirmPassword: _confirm.text,
    );
  }

  void _onOutcome(BuildContext context, ChangePasswordState state) {
    switch (state.status) {
      case ChangePasswordStatus.success:
        AppSnackBar.showOnRoot(
          message: LocaleKeys.auth_reset_password_success.t(context),
          type: SnackBarType.success,
        );
        Navigator.of(context).pop();
      case ChangePasswordStatus.failure:
        if (state.error == ChangePasswordError.offline) {
          AppSnackBar.showOnRoot(
            message: LocaleKeys.errors_offline.t(context),
            type: SnackBarType.error,
          );
        } else {
          setState(() => _currentServerError =
              LocaleKeys.settings_change_password_incorrect.t(context));
        }
      case ChangePasswordStatus.initial:
      case ChangePasswordStatus.submitting:
        break;
    }
  }

  String? _validateCurrent(String? v) => (v == null || v.isEmpty)
      ? LocaleKeys.validators_field_required.t(context)
      : null;

  String? _validateNew(String? v) {
    final base = Validators.validatePassword(v);
    if (base != null) return base;
    if (v == _current.text) {
      return LocaleKeys.settings_change_password_new_same.t(context);
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) {
      return LocaleKeys.auth_confirm_password_required.t(context);
    }
    if (v != _newPassword.text) {
      return LocaleKeys.auth_passwords_mismatch.t(context);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChangePasswordCubit>();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s20,
        QeranSpacing.s20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listenWhen: (p, c) => p.version != c.version,
        listener: _onOutcome,
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: QeranSheetHandle()),
                QeranSpacing.vs16,
                Text(
                  LocaleKeys.settings_change_password_title.t(context),
                  style: QeranTypography.title,
                ),
                QeranSpacing.vs16,
                QeranTextField(
                  controller: _current,
                  hint: LocaleKeys.settings_change_password_current_hint
                      .t(context),
                  obscureText: true,
                  showObscureToggle: true,
                  textInputAction: TextInputAction.next,
                  validator: _validateCurrent,
                  errorText: _currentServerError,
                  onChanged: _clearServerError,
                ),
                QeranSpacing.vs12,
                QeranTextField(
                  controller: _newPassword,
                  hint: LocaleKeys.auth_new_password_hint.t(context),
                  obscureText: true,
                  showObscureToggle: true,
                  textInputAction: TextInputAction.next,
                  validator: _validateNew,
                ),
                QeranSpacing.vs12,
                QeranTextField(
                  controller: _confirm,
                  hint: LocaleKeys.auth_confirm_password_hint.t(context),
                  obscureText: true,
                  showObscureToggle: true,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirm,
                  onSubmitted: (_) => _submit(cubit),
                ),
                QeranSpacing.vs20,
                QeranButton(
                  label: LocaleKeys.settings_save_changes.t(context),
                  variant: QeranButtonVariant.primaryWine,
                  loading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : () => _submit(cubit),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
