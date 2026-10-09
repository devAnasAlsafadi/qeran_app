import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_options_sheet.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../blocs/block_action_cubit.dart';
import '../blocs/block_action_state.dart';
import 'confirm_block_dialog.dart';

enum _SafetyAction { report, block }

/// A circular ⋮ button (mirrors the profile back-button style) that opens a
/// Report / Block menu for [targetUserId] — Report only for a matchmaker. On a successful block it pops the
/// enclosing route returning the blocked userId (so a list/deck can tear the
/// user down) and toasts on root. Report opens [showUserReportSheet].
class SafetyMenuButton extends StatelessWidget {
  final String targetUserId;

  const SafetyMenuButton({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlockActionCubit>(
      create: (_) => sl<BlockActionCubit>(param1: BlockOrigin.profile),
      child: _SafetyMenuButtonView(targetUserId: targetUserId),
    );
  }
}

class _SafetyMenuButtonView extends StatelessWidget {
  final String targetUserId;

  const _SafetyMenuButtonView({required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BlockActionCubit, BlockActionState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion &&
          c.outcome != BlockActionOutcome.none,
      listener: _onOutcome,
      child: Builder(
        builder: (context) => _MenuDisc(onTap: () => _openMenu(context)),
      ),
    );
  }

  void _onOutcome(BuildContext context, BlockActionState state) {
    if (state.outcome == BlockActionOutcome.success) {
      // Close the profile, hand the blocked id back for teardown, then toast
      // on root (survives the pop).
      Navigator.of(context).pop(state.blockedUserId ?? targetUserId);
      AppSnackBar.showOnRoot(
        message: (state.messageKey ?? LocaleKeys.block_success).t(context),
        type: SnackBarType.success,
      );
    } else if (state.outcome == BlockActionOutcome.failure) {
      AppSnackBar.show(
        context,
        message: (state.messageKey ?? LocaleKeys.errors_generic).t(context),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _openMenu(BuildContext context) async {
    // Capture the cubit before the menu sheet (a separate route can't read it).
    final cubit = context.read<BlockActionCubit>();
    final action = await QeranOptionsSheet.show<_SafetyAction>(
      context,
      options: _options(context),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _SafetyAction.report:
        await showUserReportSheet(context, targetUserId);
      case _SafetyAction.block:
        final ok = await confirmBlockMember(context);
        if (ok && context.mounted) cubit.block(targetUserId);
    }
  }

  /// Report, and Block — never for a matchmaker (D40): she doesn't block a
  /// member; she reports, and admin decides.
  List<QeranOption<_SafetyAction>> _options(BuildContext context) => [
    QeranOption(
      icon: Icons.flag_outlined,
      label: LocaleKeys.report_action_report_user.t(context),
      value: _SafetyAction.report,
    ),
    if (!_viewerIsMatchmaker)
      QeranOption(
        icon: Icons.block_rounded,
        label: LocaleKeys.block_action_block.t(context),
        value: _SafetyAction.block,
        danger: true,
      ),
  ];

  /// The signed-in account is a matchmaker — she reaches a member's profile
  /// from a shared card in her chat (§0.4).
  static bool get _viewerIsMatchmaker => signedInAsMatchmaker;
}

/// The ⋮ disc on a profile that opens the safety menu.
class _MenuDisc extends StatelessWidget {
  const _MenuDisc({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      shape: const CircleBorder(side: BorderSide(color: QeranColors.wine08)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.more_vert, color: QeranColors.wine, size: 20),
        ),
      ),
    );
  }
}
