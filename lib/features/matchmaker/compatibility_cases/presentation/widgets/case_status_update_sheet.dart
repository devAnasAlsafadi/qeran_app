import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/formal_request_status.dart';
import '../blocs/matchmaker_case_status_cubit.dart';
import '../blocs/matchmaker_case_status_state.dart';
import '../blocs/matchmaker_cases_list_cubit.dart';
import 'matchmaker_case_labels.dart';

/// Status update straight from a list card, without opening the case.
///
/// Always reachable: the button that opens this never hides, so every card
/// looks the same and a matchmaker is told WHY a case cannot move rather than
/// left wondering where the control went. Every target is listed every time;
/// the ones that are not legal right now are shown disabled, under a line
/// explaining the case's position.
///
/// The list is [statusUpdateTargets] filtered against the server's own
/// transition graph (`allowedNext`), so at most two are live at once. The
/// server stays authoritative — an `INVALID_STATUS_TRANSITION` is still
/// handled, it just should not happen from here.
Future<void> showCaseStatusUpdateSheet(
  BuildContext context, {
  required CompatibilityCase caseItem,
}) {
  final listCubit = context.read<MatchmakerCasesListCubit>();
  return showQeranBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider<MatchmakerCaseStatusCubit>(
      // 0 when there is no formal request yet: nothing is submittable in that
      // state, so the id is never used.
      create: (_) => sl<MatchmakerCaseStatusCubit>(
        param1: caseItem.formalRequest?.id ?? 0,
      ),
      child: BlocProvider<MatchmakerCasesListCubit>.value(
        value: listCubit,
        child: _CaseStatusUpdateSheet(caseItem: caseItem),
      ),
    ),
  );
}

class _CaseStatusUpdateSheet extends StatelessWidget {
  const _CaseStatusUpdateSheet({required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final formal = caseItem.formalRequest;
    final allowed = caseItem.canUpdateFormalRequestStatus
        ? (formal?.status.allowedNext ?? const <FormalRequestStatus>{})
        : const <FormalRequestStatus>{};

    return BlocListener<MatchmakerCaseStatusCubit, MatchmakerCaseStatusState>(
      listenWhen: (prev, curr) => prev.eventVersion != curr.eventVersion,
      listener: (listenerContext, state) =>
          _onOutcome(listenerContext, state),
      child: QeranBottomSheetScaffold(
        title: LocaleKeys.matchmaker_cases_action_update_status.t(context),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            QeranSpacing.s4,
            QeranSpacing.s20,
            QeranSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allowed.isEmpty) ...[
                _UnavailableNote(caseItem: caseItem),
                QeranSpacing.vs16,
              ],
              for (var i = 0; i < statusUpdateTargets.length; i++) ...[
                if (i > 0) QeranSpacing.vs8,
                _TargetOption(
                  target: statusUpdateTargets[i],
                  enabled: allowed.contains(statusUpdateTargets[i]),
                  caseItem: caseItem,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onOutcome(BuildContext context, MatchmakerCaseStatusState state) {
    switch (state.outcome) {
      case CaseStatusOutcome.success:
        final target = state.successfulTarget;
        final formalRequestId = caseItem.formalRequest?.id;
        if (target != null && formalRequestId != null) {
          // Patch the row in place rather than refetching: a case that just
          // went terminal would drop out of a filtered list mid-gesture.
          context.read<MatchmakerCasesListCubit>().applyStatusUpdate(
            caseId: caseItem.caseId,
            formalRequestId: formalRequestId,
            status: target,
          );
        }
        Navigator.of(context).pop();
        AppSnackBar.showOnRoot(
          message:
              state.message ??
              LocaleKeys.matchmaker_cases_update_success.t(context),
          type: SnackBarType.success,
        );
      case CaseStatusOutcome.failure:
        // The sheet stays open: the matchmaker can read the reason and pick
        // again without reopening it.
        AppSnackBar.showOnRoot(
          message: _message(context, state),
          type: SnackBarType.error,
        );
      case CaseStatusOutcome.none:
        break;
    }
  }

  /// The cubit hands back either a locale key (its own local messages) or the
  /// server's already-human text, so try the key first and fall through.
  String _message(BuildContext context, MatchmakerCaseStatusState state) {
    final raw = state.message;
    if (raw == null || raw.isEmpty) {
      return LocaleKeys.errors_generic.t(context);
    }
    final translated = raw.t(context);
    return translated == raw && raw.contains('.') && !raw.contains(' ')
        ? LocaleKeys.errors_generic.t(context)
        : translated;
  }
}

/// The informative line above a fully disabled list. Reuses the detail
/// screen's wording via [noActionsMessageKey] so the two surfaces explain a
/// stalled case identically — plus a dedicated line for a case that simply has
/// not reached the formal track yet, which is not "ended", just not started.
class _UnavailableNote extends StatelessWidget {
  const _UnavailableNote({required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final formal = caseItem.formalRequest;
    final key = formal == null
        ? LocaleKeys.matchmaker_cases_update_sheet_not_started
        : (formal.status.isTerminal
              ? LocaleKeys.matchmaker_cases_update_sheet_unavailable
              : noActionsMessageKey(currentCaseTone(caseItem)));

    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: QeranColors.goldDeep,
          ),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              key.t(context),
              style: QeranTypography.bodySm.copyWith(
                color: QeranColors.inkBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One target row. Enabled rows read like the detail screen's action buttons;
/// disabled ones keep their place in the list, dimmed and inert, so the set of
/// possible outcomes stays visible whatever state the case is in.
class _TargetOption extends StatelessWidget {
  const _TargetOption({
    required this.target,
    required this.enabled,
    required this.caseItem,
  });

  final FormalRequestStatus target;
  final bool enabled;
  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MatchmakerCaseStatusCubit>().state;
    final inFlight = state.inFlight == target;
    final tappable = enabled && !state.isBusy;
    final destructive = isDestructiveTarget(target);

    final fg = !enabled
        ? QeranColors.inkFaint
        : (destructive ? QeranColors.danger : QeranColors.inkStrong);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: enabled ? QeranColors.paper : QeranColors.neutralSurface,
        borderRadius: QeranRadii.controlR,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tappable ? () => _submit(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s16,
              vertical: QeranSpacing.s12,
            ),
            decoration: BoxDecoration(
              borderRadius: QeranRadii.controlR,
              border: Border.all(
                color: enabled
                    ? (destructive ? QeranColors.danger40 : QeranColors.wine12)
                    : QeranColors.wine08,
              ),
            ),
            child: Row(
              children: [
                Icon(formalStatusIcon(target), size: 20, color: fg),
                QeranSpacing.hs12,
                Expanded(
                  child: Text(
                    actionLabelKey(target).t(context),
                    style: QeranTypography.subtitle.copyWith(
                      color: fg,
                      fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (inFlight) const QeranLoader.inline(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<MatchmakerCaseStatusCubit>();
    if (isDestructiveTarget(target)) {
      final confirmed = await QeranConfirmDialog.show(
        context,
        title: LocaleKeys.matchmaker_cases_confirm_title.t(context),
        message: LocaleKeys.matchmaker_cases_confirm_message.t(context),
        confirmLabel: LocaleKeys.matchmaker_cases_confirm_confirm.t(context),
        cancelLabel: LocaleKeys.matchmaker_cases_confirm_dismiss.t(context),
      );
      if (!confirmed) return;
    }
    cubit.submit(target);
  }
}
