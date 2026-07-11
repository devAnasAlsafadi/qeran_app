import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_account_cubit.dart';
import '../blocs/matchmaker_account_state.dart';

/// Change-password bottom sheet — shares the screen's [MatchmakerAccountCubit].
/// Current + new password (obscured, with the built-in eye). On success: toast +
/// close. A wrong current password (the endpoint has no errorCode) shows the
/// server message inline under the current-password field.
Future<void> showMatchmakerChangePasswordSheet(
  BuildContext context, {
  required MatchmakerAccountCubit cubit,
}) {
  return showQeranBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _ChangePasswordSheet(),
    ),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  String? _inlineError;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _current.text.isNotEmpty && _newPassword.text.isNotEmpty;

  void _onChanged(String _) {
    // Always rebuild so the Save button's `_canSave` re-evaluates per keystroke
    // (also clears any inline error once present).
    setState(() {
      if (_inlineError != null) _inlineError = null;
    });
  }

  void _save(MatchmakerAccountCubit cubit) {
    if (!_canSave) return;
    cubit.changePassword(
      currentPassword: _current.text,
      newPassword: _newPassword.text,
    );
  }

  void _onOutcome(BuildContext context, MatchmakerAccountState state) {
    if (state.outcome == MatchmakerAccountOutcome.changePasswordSuccess) {
      AppSnackBar.showOnRoot(
        message: LocaleKeys.matchmaker_account_password_changed.t(context),
        type: SnackBarType.success,
      );
      Navigator.of(context).pop();
    } else if (state.outcome == MatchmakerAccountOutcome.failure &&
        state.errorKind == MatchmakerAccountErrorKind.incorrectPassword) {
      setState(() => _inlineError =
          (state.actionErrorKey ?? LocaleKeys.errors_generic).t(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerAccountCubit>();
    return BlocConsumer<MatchmakerAccountCubit, MatchmakerAccountState>(
      listenWhen: (p, c) => p.eventVersion != c.eventVersion,
      listener: _onOutcome,
      builder: (context, state) {
        final saving =
            state.inFlight == MatchmakerAccountAction.changingPassword;
        return QeranBottomSheetScaffold(
          title:
              LocaleKeys.matchmaker_account_change_password_title.t(context),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s4,
              QeranSpacing.s20,
              QeranSpacing.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QeranTextField(
                  controller: _current,
                  hint: LocaleKeys.matchmaker_account_current_password_hint
                      .t(context),
                  obscureText: true,
                  showObscureToggle: true,
                  textInputAction: TextInputAction.next,
                  errorText: _inlineError,
                  onChanged: _onChanged,
                ),
                QeranSpacing.vs12,
                QeranTextField(
                  controller: _newPassword,
                  hint: LocaleKeys.matchmaker_account_new_password_hint
                      .t(context),
                  obscureText: true,
                  showObscureToggle: true,
                  textInputAction: TextInputAction.done,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _save(cubit),
                ),
              ],
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s8,
              QeranSpacing.s20,
              QeranSpacing.s16,
            ),
            child: QeranButton(
              label: LocaleKeys.matchmaker_account_save.t(context),
              variant: QeranButtonVariant.primaryWine,
              loading: saving,
              onPressed:
                  (!_canSave || state.isBusy) ? null : () => _save(cubit),
            ),
          ),
        );
      },
    );
  }
}
