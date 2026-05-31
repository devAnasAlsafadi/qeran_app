import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Matchmaker account / settings screen. The full profile/edit flows are
/// M6; for now it hosts the working **logout** action, reusing the user
/// app's exact mechanism — `UserSessionCubit.signOut()` (clears token +
/// prefs) then a login redirect that clears the nav stack.
class MatchmakerAccountScreen extends StatelessWidget {
  const MatchmakerAccountScreen({super.key});

  // The shell uses `extendBody: true` with a curved bottom-nav, so the tab
  // body extends behind it — reserve space so the CTA clears the nav.
  static const double _navReserve = 96;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_account_title.t(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: QeranEmptyState(
              icon: Icons.person_outline_rounded,
              title: LocaleKeys.matchmaker_empty_account_title.t(context),
              message: LocaleKeys.matchmaker_empty_account_message.t(context),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s8,
              QeranSpacing.s20,
              MediaQuery.of(context).padding.bottom + _navReserve,
            ),
            child: QeranButton(
              label: LocaleKeys.common_logout.t(context),
              variant: QeranButtonVariant.destructive,
              leadingIcon: Icons.logout_rounded,
              onPressed: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm → clear the session via the shared [UserSessionCubit.signOut]
  /// (same path the user app uses) → redirect to login, removing every
  /// route so back can't re-enter the authenticated shell. Removing the
  /// `matchmakerHome` route disposes `MatchmakerHomeScreen`, which tears
  /// down the matchmaker SignalR connection it owns (4c-1) automatically.
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<UserSessionCubit>().signOut();
    if (!context.mounted) return;
    NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.loginScreen);
  }
}

/// Identity-styled logout confirm — mirrors the M3b terminal-status dialog
/// (DS tokens, ghost cancel + destructive confirm). Pops `true` to confirm.
class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: QeranColors.paper,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: QeranRadii.cardR),
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.dialogs_logout_title.t(context),
              style: QeranTypography.title,
            ),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.dialogs_logout_message.t(context),
              style: QeranTypography.body,
            ),
            QeranSpacing.vs20,
            Row(
              children: [
                Expanded(
                  child: QeranButton(
                    label: LocaleKeys.common_cancel.t(context),
                    variant: QeranButtonVariant.ghost,
                    size: QeranButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                QeranSpacing.hs12,
                Expanded(
                  child: QeranButton(
                    label: LocaleKeys.common_logout.t(context),
                    variant: QeranButtonVariant.destructive,
                    size: QeranButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
