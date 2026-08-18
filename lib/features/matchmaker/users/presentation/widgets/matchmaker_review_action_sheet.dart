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
import '../../domain/entities/image_request_status.dart';
import '../blocs/matchmaker_user_actions_cubit.dart';
import '../blocs/matchmaker_user_actions_state.dart';
import 'reject_reason_sheet.dart';

/// Confirm sheet opened by the pending card's موافقة button — offers Approve
/// (direct), Reject (opens the reason sheet), and — when the user has no
/// profile image ([hasNoImage]) — Request-photo, for one user. Owns a scoped
/// [MatchmakerUserActionsCubit] (param1: userId); pops `true` on ANY success —
/// approve, reject, or request-photo — so the caller refetches the row. A
/// failure shows a snackbar and keeps the sheet open for a retry.
///
/// [imageRequestStatus] is the server's persisted answer to "have I already
/// asked?" — `pending` turns the request button into a disabled awaiting
/// state so the matchmaker doesn't nag a user who simply hasn't uploaded yet.
Future<bool?> showMatchmakerReviewSheet(
  BuildContext context, {
  required String userId,
  bool hasNoImage = false,
  MatchmakerImageRequestStatus imageRequestStatus =
      MatchmakerImageRequestStatus.none,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
    useSafeArea: true,
    builder: (_) => BlocProvider<MatchmakerUserActionsCubit>(
      create: (_) => sl<MatchmakerUserActionsCubit>(param1: userId),
      child: _ReviewActionSheet(
        hasNoImage: hasNoImage,
        imageRequestStatus: imageRequestStatus,
      ),
    ),
  );
}

class _ReviewActionSheet extends StatelessWidget {
  const _ReviewActionSheet({
    required this.hasNoImage,
    required this.imageRequestStatus,
  });

  final bool hasNoImage;
  final MatchmakerImageRequestStatus imageRequestStatus;

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
            _ReviewButtons(
              hasNoImage: hasNoImage,
              imageRequestStatus: imageRequestStatus,
            ),
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
          message: LocaleKeys.matchmaker_profile_request_image_success.t(
            context,
          ),
          type: SnackBarType.success,
        );
        // Pop `true` so the host refetches the row: the refreshed payload
        // carries imageRequestStatus == pending, which renders the awaiting
        // state. Deliberately NOT a local flag — that would not survive a
        // relaunch and would then lie about whether a request is outstanding.
        Navigator.of(context).pop(true);
      case MatchmakerActionOutcome.failure:
        if (state.errorKind == MatchmakerActionErrorKind.unauthorized) {
          AppSnackBar.showOnRoot(
            message: LocaleKeys.matchmaker_user_not_assigned.t(context),
            type: SnackBarType.error,
          );
          Navigator.of(context).pop(false);
        } else {
          AppSnackBar.show(
            context,
            message: (state.errorMessage ?? LocaleKeys.errors_generic).t(
              context,
            ),
            type: SnackBarType.error,
          );
        }
      case MatchmakerActionOutcome.none:
        break;
    }
  }
}

/// The stacked action buttons — موافقة (filled wine) · رفض (destructive) ·
/// [طلب صورة when the user has no photo] · إلغاء (ghost). The active action
/// shows an inline loader; all disable while any action is in flight.
class _ReviewButtons extends StatelessWidget {
  const _ReviewButtons({
    required this.hasNoImage,
    required this.imageRequestStatus,
  });

  final bool hasNoImage;
  final MatchmakerImageRequestStatus imageRequestStatus;

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
            // `approved` means the user uploaded after the request, so there
            // is nothing left to ask for — the button drops out entirely, the
            // same as for a user who already had a photo.
            if (hasNoImage &&
                imageRequestStatus !=
                    MatchmakerImageRequestStatus.approved) ...[
              QeranButton(
                label:
                    (imageRequestStatus.isAwaitingUpload
                            ? LocaleKeys
                                  .matchmaker_profile_request_image_awaiting
                            : LocaleKeys
                                  .matchmaker_profile_action_request_image)
                        .t(context),
                variant: QeranButtonVariant.ghost,
                leadingIcon: imageRequestStatus.isAwaitingUpload
                    ? Icons.hourglass_top_rounded
                    : Icons.add_a_photo_outlined,
                loading: state.inFlight == MatchmakerUserAction.requestImage,
                // Awaiting: already asked, the user simply hasn't uploaded
                // yet. Disabled so a second request can't be fired.
                onPressed: busy || imageRequestStatus.isAwaitingUpload
                    ? null
                    : cubit.requestImage,
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
