import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/formal_request_status.dart';
import '../blocs/matchmaker_case_status_cubit.dart';
import 'matchmaker_case_labels.dart';

/// Status-update actions for the case detail. Shown ONLY when the case is
/// actionable (`canUpdateFormalRequestStatus` && a non-null formalRequest
/// with legal next states); otherwise a muted note. Renders one button per
/// `allowedNext` status — the forward step as a primary CTA, each terminal
/// closure as a danger button gated behind a confirm dialog. Buttons disable
/// while a submit is in flight; the active one shows an inline loader.
class CaseStatusActions extends StatelessWidget {
  const CaseStatusActions({super.key, required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final formal = caseItem.formalRequest;
    final next =
        formal?.status.allowedNext ?? const <FormalRequestStatus>{};
    if (!caseItem.canUpdateFormalRequestStatus || formal == null || next.isEmpty) {
      return const _NoActionsNote();
    }

    final forward =
        next.where((s) => !isDestructiveTarget(s)).toList(growable: false);
    final destructive =
        next.where(isDestructiveTarget).toList(growable: false);

    final state = context.watch<MatchmakerCaseStatusCubit>().state;
    final cubit = context.read<MatchmakerCaseStatusCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final target in forward) ...[
          QeranButton(
            label: actionLabelKey(target).t(context),
            variant: QeranButtonVariant.primary,
            leadingIcon: formalStatusIcon(target),
            loading: state.inFlight == target,
            onPressed: state.isBusy ? null : () => cubit.submit(target),
          ),
          QeranSpacing.vs12,
        ],
        if (destructive.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < destructive.length; i++) ...[
                if (i > 0) QeranSpacing.hs12,
                Expanded(
                  child: QeranButton(
                    label: actionLabelKey(destructive[i]).t(context),
                    variant: QeranButtonVariant.destructive,
                    size: QeranButtonSize.md,
                    leadingIcon: formalStatusIcon(destructive[i]),
                    loading: state.inFlight == destructive[i],
                    onPressed: state.isBusy
                        ? null
                        : () => _confirmThenSubmit(
                              context,
                              cubit,
                              destructive[i],
                            ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Future<void> _confirmThenSubmit(
    BuildContext context,
    MatchmakerCaseStatusCubit cubit,
    FormalRequestStatus target,
  ) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.matchmaker_cases_confirm_title.t(context),
      message: LocaleKeys.matchmaker_cases_confirm_message.t(context),
      confirmLabel: LocaleKeys.matchmaker_cases_confirm_confirm.t(context),
      cancelLabel: LocaleKeys.matchmaker_cases_confirm_dismiss.t(context),
    );
    if (confirmed && context.mounted) cubit.submit(target);
  }
}

class _NoActionsNote extends StatelessWidget {
  const _NoActionsNote();

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: QeranColors.inkMuted,
          ),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              LocaleKeys.matchmaker_cases_no_actions_note.t(context),
              style: QeranTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}
