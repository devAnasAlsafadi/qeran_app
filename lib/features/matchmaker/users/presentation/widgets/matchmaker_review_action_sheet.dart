import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_sheet_handle.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_user_actions_cubit.dart';
import '../blocs/matchmaker_user_actions_state.dart';
import 'reject_reason_sheet.dart';

/// Confirm sheet opened by the pending card's موافقة button — offers Approve
/// (direct), Reject (opens the reason sheet), and — when the user has no
/// profile image ([hasNoImage]) — Request-photo, for one user. Owns a scoped
/// [MatchmakerUserActionsCubit] (param1: userId); pops `true` on approve/reject
/// success so the caller refreshes the list. Request-photo pops without a
/// refresh (the row's status is unchanged). A failure shows a snackbar and
/// keeps the sheet open for a retry.
Future<bool?> showMatchmakerReviewSheet(
  BuildContext context, {
  required String userId,
  bool hasNoImage = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
    useSafeArea: true,
    builder: (_) => BlocProvider<MatchmakerUserActionsCubit>(
      create: (_) => sl<MatchmakerUserActionsCubit>(param1: userId),
      child: _ReviewActionSheet(hasNoImage: hasNoImage),
    ),
  );
}

class _ReviewActionSheet extends StatelessWidget {
  const _ReviewActionSheet({required this.hasNoImage});

  final bool hasNoImage;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchmakerUserActionsCubit, MatchmakerUserActionsState>(
      listenWhen: (prev, curr) => prev.eventVersion != curr.eventVersion,
      listener: _onOutcome,
      child: Container(
        decoration: const BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.domeTop,
          boxShadow: QeranShadows.e3,
        ),
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s24,
          QeranSpacing.s12,
          QeranSpacing.s24,
          QeranSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const QeranSheetHandle(),
            QeranSpacing.vs20,
            Text(
              LocaleKeys.matchmaker_users_review_title.t(context),
              style: QeranTypography.headline,
            ),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.matchmaker_users_review_subtitle.t(context),
              style: QeranTypography.body,
            ),
            QeranSpacing.vs20,
            _ReviewButtons(hasNoImage: hasNoImage),
          ],
        ),
      ),
    );
  }

  void _onOutcome(BuildContext context, MatchmakerUserActionsState state) {
    switch (state.outcome) {
      case MatchmakerActionOutcome.approveSuccess:
        AppSnackBar.showOnRoot(
          message: LocaleKeys.matchmaker_profile_approve_success.t(context),
          type: SnackBarType.success,
        );
        Navigator.of(context).pop(true);
      case MatchmakerActionOutcome.rejectSuccess:
        AppSnackBar.showOnRoot(
          message: LocaleKeys.matchmaker_profile_reject_success.t(context),
          type: SnackBarType.success,
        );
        Navigator.of(context).pop(true);
      case MatchmakerActionOutcome.requestImageSuccess:
        AppSnackBar.showOnRoot(
          message:
              LocaleKeys.matchmaker_profile_request_image_success.t(context),
          type: SnackBarType.success,
        );
        Navigator.of(context).pop();
      case MatchmakerActionOutcome.failure:
        AppSnackBar.show(
          context,
          message: (state.errorMessage ?? LocaleKeys.errors_generic).t(context),
          type: SnackBarType.error,
        );
      case MatchmakerActionOutcome.none:
        break;
    }
  }
}

/// The stacked action buttons — موافقة (filled wine) · رفض (destructive) ·
/// [طلب صورة when the user has no photo] · إلغاء (ghost). The active action
/// shows an inline loader; all disable while any action is in flight.
class _ReviewButtons extends StatelessWidget {
  const _ReviewButtons({required this.hasNoImage});

  final bool hasNoImage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerUserActionsCubit, MatchmakerUserActionsState>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerUserActionsCubit>();
        final busy = state.isBusy;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QeranButton(
              label: LocaleKeys.matchmaker_users_action_approve.t(context),
              variant: QeranButtonVariant.primaryWine,
              leadingIcon: Icons.check_circle_outline_rounded,
              loading: state.inFlight == MatchmakerUserAction.approve,
              onPressed: busy ? null : cubit.approve,
            ),
            QeranSpacing.vs8,
            QeranButton(
              label: LocaleKeys.matchmaker_profile_action_reject.t(context),
              variant: QeranButtonVariant.destructive,
              leadingIcon: Icons.cancel_outlined,
              loading: state.inFlight == MatchmakerUserAction.reject,
              onPressed: busy ? null : () => _onReject(context, cubit),
            ),
            QeranSpacing.vs8,
            if (hasNoImage) ...[
              QeranButton(
                label: LocaleKeys.matchmaker_profile_action_request_image
                    .t(context),
                variant: QeranButtonVariant.ghost,
                leadingIcon: Icons.add_a_photo_outlined,
                loading: state.inFlight == MatchmakerUserAction.requestImage,
                onPressed: busy ? null : cubit.requestImage,
              ),
              QeranSpacing.vs8,
            ],
            QeranButton(
              label: LocaleKeys.matchmaker_profile_action_cancel.t(context),
              variant: QeranButtonVariant.ghost,
              size: QeranButtonSize.md,
              onPressed: busy ? null : () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onReject(
    BuildContext context,
    MatchmakerUserActionsCubit cubit,
  ) async {
    final reason = await showRejectReasonSheet(context);
    if (reason != null && context.mounted) cubit.reject(reason);
  }
}
