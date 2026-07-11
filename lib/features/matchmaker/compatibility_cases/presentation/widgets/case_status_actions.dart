import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/formal_request_status.dart';
import '../blocs/matchmaker_case_status_cubit.dart';
import 'case_timeline.dart';
import 'matchmaker_case_labels.dart';

/// Status-update actions for the case detail. Shown ONLY when the case is
/// actionable (`canUpdateFormalRequestStatus` && a non-null formalRequest
/// with legal next states); otherwise a calm informative card that says WHY
/// there's nothing to do (complete / ended / awaiting the other party) — never
/// a dead grey note. Renders one button per `allowedNext` status — the forward
/// step as a primary CTA, each terminal closure as a danger button gated
/// behind a confirm dialog. The active button becomes an "updating…" state
/// while a submit is in flight; others disable.
class CaseStatusActions extends StatelessWidget {
  const CaseStatusActions({super.key, required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final formal = caseItem.formalRequest;
    final next =
        formal?.status.allowedNext ?? const <FormalRequestStatus>{};
    if (!caseItem.canUpdateFormalRequestStatus ||
        formal == null ||
        next.isEmpty) {
      return _NoActionsCard(caseItem: caseItem);
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
          if (state.inFlight == target)
            const _UpdatingButton()
          else
            QeranButton(
              label: actionLabelKey(target).t(context),
              variant: QeranButtonVariant.primary,
              leadingIcon: Icons.check_circle_rounded,
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

/// The forward primary while its submit is in flight — a dimmed gold button
/// with an inline spinner + "جارٍ التحديث…" (56 → 54 to match the CTA).
class _UpdatingButton extends StatelessWidget {
  const _UpdatingButton();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        height: 54,
        decoration: const BoxDecoration(
          color: QeranColors.gold,
          borderRadius: QeranRadii.controlR,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const QeranLoader.inline(color: QeranColors.wine),
            QeranSpacing.hs8,
            Text(
              LocaleKeys.matchmaker_cases_updating.t(context),
              style: QeranTypography.subtitle.copyWith(color: QeranColors.wine),
            ),
          ],
        ),
      ),
    );
  }
}

/// The no-actions informative card — cream-surface + a tinted icon chip that
/// explains WHY there's nothing to do, tied to the timeline's current step:
/// complete (success) · ended (rejected/closed/cancelled) · awaiting the other
/// party (still in progress but not this matchmaker's turn / pre-formal).
class _NoActionsCard extends StatelessWidget {
  const _NoActionsCard({required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final tone = _currentTone(caseItem);
    final (:messageKey, :icon, :accent, :bg) = _style(tone);

    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: accent, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: QeranRadii.controlR,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accent),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              messageKey.t(context),
              style: QeranTypography.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  CaseStepTone _currentTone(CompatibilityCase c) {
    for (final step in buildCaseTimeline(c)) {
      if (step.state == CaseStepState.current) return step.tone;
    }
    return CaseStepTone.normal;
  }

  ({String messageKey, IconData icon, Color accent, Color bg}) _style(
    CaseStepTone tone,
  ) =>
      switch (tone) {
        CaseStepTone.success => (
            messageKey: LocaleKeys.matchmaker_cases_no_actions_complete,
            icon: Icons.verified_rounded,
            accent: QeranColors.goldDeep,
            bg: QeranColors.creamSurface,
          ),
        CaseStepTone.ended => (
            messageKey: LocaleKeys.matchmaker_cases_no_actions_ended,
            icon: Icons.flag_rounded,
            accent: QeranColors.wine,
            bg: QeranColors.creamSurface,
          ),
        CaseStepTone.normal => (
            messageKey: LocaleKeys.matchmaker_cases_no_actions_waiting,
            icon: Icons.hourglass_top_rounded,
            accent: QeranColors.goldDeep,
            bg: QeranColors.creamSurface,
          ),
      };
}
