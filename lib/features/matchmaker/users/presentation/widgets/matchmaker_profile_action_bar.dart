import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_profile_detail_cubit.dart';
import '../blocs/matchmaker_profile_detail_state.dart';
import '../blocs/matchmaker_user_actions_cubit.dart';
import '../blocs/matchmaker_user_actions_state.dart';
import 'reject_reason_sheet.dart';

/// Bottom action bar for the matchmaker profile detail. Visible ONLY while
/// the profile is `PendingReview`. Approve + Reject always show; Request-
/// photo shows only when the profile carries no image. Buttons disable
/// while any action is in flight, and the active one shows an inline loader.
class MatchmakerProfileActionBar extends StatelessWidget {
  const MatchmakerProfileActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<MatchmakerProfileDetailCubit>().state;
    if (detail is! MatchmakerProfileDetailLoaded) {
      return const SizedBox.shrink();
    }
    final profile = detail.profile;
    if (profile.profileStatus != ProfileStatus.pendingReview) {
      return const SizedBox.shrink();
    }
    final hasNoImage = profile.profileImage == null && profile.images.isEmpty;

    final actions = context.watch<MatchmakerUserActionsCubit>().state;
    final cubit = context.read<MatchmakerUserActionsCubit>();

    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        border: Border(top: BorderSide(color: QeranColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            QeranSpacing.s12,
            QeranSpacing.s20,
            QeranSpacing.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasNoImage) ...[
                QeranButton(
                  label: LocaleKeys.matchmaker_profile_action_request_image
                      .t(context),
                  variant: QeranButtonVariant.ghost,
                  size: QeranButtonSize.md,
                  leadingIcon: Icons.add_a_photo_outlined,
                  loading:
                      actions.inFlight == MatchmakerUserAction.requestImage,
                  onPressed: actions.isBusy ? null : cubit.requestImage,
                ),
                QeranSpacing.vs8,
              ],
              Row(
                children: [
                  Expanded(
                    child: QeranButton(
                      label: LocaleKeys.matchmaker_profile_action_reject
                          .t(context),
                      variant: QeranButtonVariant.destructive,
                      loading:
                          actions.inFlight == MatchmakerUserAction.reject,
                      onPressed: actions.isBusy
                          ? null
                          : () => _onReject(context, cubit),
                    ),
                  ),
                  QeranSpacing.hs12,
                  Expanded(
                    child: QeranButton(
                      label: LocaleKeys.matchmaker_profile_action_approve
                          .t(context),
                      variant: QeranButtonVariant.primary,
                      loading:
                          actions.inFlight == MatchmakerUserAction.approve,
                      onPressed: actions.isBusy
                          ? null
                          : () => _onApprove(context, cubit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onApprove(
    BuildContext context,
    MatchmakerUserActionsCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ApproveConfirmDialog(),
    );
    if (confirmed == true && context.mounted) cubit.approve();
  }

  Future<void> _onReject(
    BuildContext context,
    MatchmakerUserActionsCubit cubit,
  ) async {
    final reason = await showRejectReasonSheet(context);
    if (reason != null && context.mounted) cubit.reject(reason);
  }
}

/// Identity-styled confirm dialog for approve (no Material defaults). Pops
/// `true` to confirm, `false`/`null` to cancel.
class _ApproveConfirmDialog extends StatelessWidget {
  const _ApproveConfirmDialog();

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
              LocaleKeys.matchmaker_profile_approve_confirm_title.t(context),
              style: QeranTypography.title,
            ),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.matchmaker_profile_approve_confirm_message.t(context),
              style: QeranTypography.body,
            ),
            QeranSpacing.vs20,
            Row(
              children: [
                Expanded(
                  child: QeranButton(
                    label: LocaleKeys.matchmaker_profile_action_cancel
                        .t(context),
                    variant: QeranButtonVariant.ghost,
                    size: QeranButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                QeranSpacing.hs12,
                Expanded(
                  child: QeranButton(
                    label: LocaleKeys.matchmaker_profile_action_approve
                        .t(context),
                    variant: QeranButtonVariant.primary,
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
