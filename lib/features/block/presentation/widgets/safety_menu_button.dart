import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/design_system/widgets/qeran_sheet_handle.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/block_action_cubit.dart';
import '../blocs/block_action_state.dart';

enum _SafetyAction { report, block }

/// A circular ⋮ button (mirrors the profile back-button style) that opens a
/// Report / Block menu for [targetUserId]. On a successful block it pops the
/// enclosing route returning the blocked userId (so a list/deck can tear the
/// user down) and toasts on root. Report is delegated to [showReportSheet].
class SafetyMenuButton extends StatelessWidget {
  final String targetUserId;

  const SafetyMenuButton({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlockActionCubit>(
      create: (_) => sl<BlockActionCubit>(),
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
      listener: (context, state) {
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
            message:
                (state.messageKey ?? LocaleKeys.errors_generic).t(context),
            type: SnackBarType.error,
          );
        }
      },
      child: Builder(
        builder: (context) => Material(
          color: QeranColors.paper,
          shape: const CircleBorder(
            side: BorderSide(color: QeranColors.wine08),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _openMenu(context),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.more_vert, color: QeranColors.wine, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    // Capture the cubit before the menu sheet (a separate route can't read it).
    final cubit = context.read<BlockActionCubit>();
    final action = await showModalBottomSheet<_SafetyAction>(
      context: context,
      backgroundColor: QeranColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
      builder: (_) => const _SafetyMenuSheet(),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _SafetyAction.report:
        await showReportSheet(context, targetUserId: targetUserId);
      case _SafetyAction.block:
        final ok = await QeranConfirmDialog.show(
          context,
          title: LocaleKeys.block_confirm_title.t(context),
          message: LocaleKeys.block_confirm_body.t(context),
          confirmLabel: LocaleKeys.block_confirm_button.t(context),
          cancelLabel: LocaleKeys.common_cancel.t(context),
          icon: Icons.block_rounded,
        );
        if (ok && context.mounted) cubit.block(targetUserId);
    }
  }
}

class _SafetyMenuSheet extends StatelessWidget {
  const _SafetyMenuSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s12,
          QeranSpacing.s12,
          QeranSpacing.s12,
          QeranSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: QeranSheetHandle()),
            QeranSpacing.vs12,
            _Row(
              icon: Icons.flag_outlined,
              label: LocaleKeys.report_action_report_user.t(context),
              onTap: () => Navigator.of(context).pop(_SafetyAction.report),
            ),
            _Row(
              icon: Icons.block_rounded,
              label: LocaleKeys.block_action_block.t(context),
              danger: true,
              onTap: () => Navigator.of(context).pop(_SafetyAction.block),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? QeranColors.danger : QeranColors.wine;
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.cardR,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            QeranSpacing.hs12,
            Text(
              label,
              style: QeranTypography.body.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
