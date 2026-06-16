import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_account_cubit.dart';
import '../blocs/matchmaker_account_state.dart';
import '../widgets/matchmaker_account_body.dart';
import '../widgets/matchmaker_change_password_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../widgets/matchmaker_edit_name_sheet.dart';

/// Matchmaker account / settings screen (pushed from the app-bar). Loads `/me`,
/// renders the header + settings rows, and wires name / language /
/// support / terms / deactivate / logout. Edit-name uses a minimal inline sheet
/// for S1b; S1c formalizes it (+ change-password).
class MatchmakerAccountScreen extends StatelessWidget {
  const MatchmakerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerAccountCubit>(
      create: (_) => sl<MatchmakerAccountCubit>()..load(),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_account_title.t(context),
      ),
      body: BlocConsumer<MatchmakerAccountCubit, MatchmakerAccountState>(
        listenWhen: (prev, curr) => prev.eventVersion != curr.eventVersion,
        listener: _onOutcome,
        builder: _buildBody,
      ),
    );
  }

  Widget _buildBody(BuildContext context, MatchmakerAccountState state) {
    final cubit = context.read<MatchmakerAccountCubit>();
    final me = state.me;
    if (me == null) {
      if (state.status == MatchmakerAccountStatus.failure) {
        return QeranErrorState(
          title: LocaleKeys.matchmaker_account_load_error.t(context),
          message: (state.loadErrorKey ?? LocaleKeys.errors_generic).t(context),
          retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
          onRetry: cubit.load,
        );
      }
      return const Center(child: QeranLoader());
    }
    return MatchmakerAccountBody(
      me: me,
      onEditName: () => _editName(context),
      onChangePassword: () => _changePassword(context),
      onLanguage: () =>
          NavigationManager.navigateTo(context, RouteNames.settingsLanguage),
      onComingSoon: () => AppSnackBar.show(
        context,
        message: LocaleKeys.settings_coming_soon.t(context),
        type: SnackBarType.info,
      ),
      onSupport: () =>
          NavigationManager.navigateTo(context, RouteNames.settingsSupport),
      onTerms: () =>
          NavigationManager.navigateTo(context, RouteNames.settingsTerms),
      onContact: () => _contact(context),
      onDeactivate: () => _deactivate(context),
      onLogout: () => _logout(context),
      bottomReserve: MediaQuery.of(context).padding.bottom,
    );
  }

  void _onOutcome(BuildContext context, MatchmakerAccountState state) {
    switch (state.outcome) {
      // Name / password successes + their inline validation are owned by their
      // sheets (toast + close / inline) — the screen ignores them here.
      case MatchmakerAccountOutcome.saveNameSuccess:
      case MatchmakerAccountOutcome.changePasswordSuccess:
        break;
      case MatchmakerAccountOutcome.uploadPhotoSuccess:
        _toast(context, LocaleKeys.matchmaker_account_photo_updated,
            SnackBarType.success);
      case MatchmakerAccountOutcome.deactivateSuccess:
        _clearSessionAndExit(
          context,
          successKey: LocaleKeys.matchmaker_account_deactivate_success,
        );
      case MatchmakerAccountOutcome.failure:
        // Validation (edit-name) / incorrect-password (change-password) show
        // inline in their sheets; only toast the rest (photo / deactivate / …).
        if (state.errorKind == MatchmakerAccountErrorKind.validation ||
            state.errorKind == MatchmakerAccountErrorKind.incorrectPassword) {
          break;
        }
        _toast(context, state.actionErrorKey ?? LocaleKeys.errors_generic,
            SnackBarType.error);
      case MatchmakerAccountOutcome.none:
        break;
    }
  }

  void _toast(BuildContext context, String key, SnackBarType type) =>
      AppSnackBar.show(context, message: key.t(context), type: type);

  void _editName(BuildContext context) {
    final cubit = context.read<MatchmakerAccountCubit>();
    final me = cubit.state.me;
    if (me == null) return;
    showMatchmakerEditNameSheet(context, cubit: cubit, currentName: me.name);
  }

  void _changePassword(BuildContext context) {
    showMatchmakerChangePasswordSheet(
      context,
      cubit: context.read<MatchmakerAccountCubit>(),
    );
  }

  void _contact(BuildContext context) =>
      NavigationManager.navigateTo(context, RouteNames.matchmakerContact);

  Future<void> _deactivate(BuildContext context) async {
    final cubit = context.read<MatchmakerAccountCubit>();
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.matchmaker_account_deactivate_confirm_title.t(context),
      message:
          LocaleKeys.matchmaker_account_deactivate_confirm_message.t(context),
      confirmLabel: LocaleKeys.matchmaker_account_row_deactivate.t(context),
      icon: Icons.person_off_outlined,
    );
    if (confirmed && context.mounted) cubit.deactivate();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.dialogs_logout_title.t(context),
      message: LocaleKeys.dialogs_logout_message.t(context),
      confirmLabel: LocaleKeys.common_logout.t(context),
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<UserSessionCubit>().signOut();
    if (!context.mounted) return;
    NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.loginScreen);
  }

  /// Deactivate succeeded — clear the session (same path as logout; removing
  /// `matchmakerHome` tears down the matchmaker SignalR it owns) and redirect to
  /// login, then surface the confirmation on the root overlay (survives the pop).
  Future<void> _clearSessionAndExit(
    BuildContext context, {
    required String successKey,
  }) async {
    final message = successKey.t(context);
    await context.read<UserSessionCubit>().signOut();
    if (!context.mounted) return;
    NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.loginScreen);
    await AppSnackBar.showOnRoot(message: message, type: SnackBarType.success);
  }
}
