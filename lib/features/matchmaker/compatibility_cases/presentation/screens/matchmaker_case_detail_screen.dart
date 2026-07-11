import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/design_system/widgets/qeran_stepper.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../domain/entities/compatibility_case.dart';
import '../blocs/matchmaker_case_status_cubit.dart';
import '../blocs/matchmaker_case_status_state.dart';
import '../widgets/case_participants_pair.dart';
import '../widgets/case_status_actions.dart';
import '../widgets/case_status_section.dart';
import '../widgets/case_timeline.dart';

/// Case detail (M3b). Receives the already-loaded [CompatibilityCase] (the
/// list payload is the whole truth — there's no detail endpoint), shows both
/// participants + the stage timeline + every status signal, and drives the
/// server-validated formal-request status update. A successful update shows a
/// brief inline confirmation then pops back with `true` so the list refreshes;
/// an `INVALID_STATUS_TRANSITION` (the case may have moved / closed) pops with
/// `true` immediately.
class MatchmakerCaseDetailScreen extends StatelessWidget {
  const MatchmakerCaseDetailScreen({super.key, required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerCaseStatusCubit>(
      create: (_) => sl<MatchmakerCaseStatusCubit>(
        param1: caseItem.formalRequest?.id ?? 0,
      ),
      child: _CaseDetailView(caseItem: caseItem),
    );
  }
}

class _CaseDetailView extends StatefulWidget {
  const _CaseDetailView({required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  State<_CaseDetailView> createState() => _CaseDetailViewState();
}

class _CaseDetailViewState extends State<_CaseDetailView> {
  /// Set true once an update succeeds — swaps the actions for a success card
  /// for a beat before popping back to the refreshed list.
  bool _success = false;

  CompatibilityCase get caseItem => widget.caseItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_cases_detail_title.t(context),
      ),
      body: BlocListener<MatchmakerCaseStatusCubit, MatchmakerCaseStatusState>(
        listenWhen: (prev, curr) => prev.eventVersion != curr.eventVersion,
        listener: _onOutcome,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(QeranSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroPanel(caseItem: caseItem),
                QeranSpacing.vs24,
                _TimelineSection(caseItem: caseItem),
                QeranSpacing.vs24,
                CaseStatusSection(caseItem: caseItem),
                QeranSpacing.vs16,
                if (_success)
                  const _SuccessCard()
                else
                  CaseStatusActions(caseItem: caseItem),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onOutcome(
    BuildContext context,
    MatchmakerCaseStatusState state,
  ) async {
    switch (state.outcome) {
      case CaseStatusOutcome.success:
        // Show the inline confirmation, then pop back to the refreshed list.
        setState(() => _success = true);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        // Use the State's context after the gap (the param may be stale).
        NavigationManager.pop(this.context, true);
      case CaseStatusOutcome.failure:
        if (state.isInvalidTransition) {
          // Local message instead of the server's numeric text; pop so the
          // list refetches the case's real (possibly moved) status.
          AppSnackBar.showOnRoot(
            message:
                (state.message ?? LocaleKeys.matchmaker_cases_invalid_transition)
                    .t(context),
            type: SnackBarType.error,
          );
          NavigationManager.pop(context, true);
        } else {
          AppSnackBar.show(
            context,
            message: (state.message ?? LocaleKeys.errors_generic).t(context),
            type: SnackBarType.error,
          );
        }
      case CaseStatusOutcome.none:
        break;
    }
  }
}

/// Participants hero — a cream-surface panel with the two participants
/// (monogram/photo + name + gender·age + role chip) joined by a gold heart.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s20),
      decoration: const BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.panelR,
        boxShadow: QeranShadows.e1,
      ),
      child: CaseParticipantsPair(
        myUser: caseItem.myUser,
        otherUser: caseItem.otherUser,
        avatarSize: 72,
        showRoleLabels: true,
      ),
    );
  }
}

/// The stage timeline — a gold-bar header + the reusable [QeranStepper], fed
/// by the backend-derived [buildCaseTimeline] projection.
class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final steps = [
      for (final s in buildCaseTimeline(caseItem))
        QeranStepData(
          label: s.labelKey.t(context),
          state: _mapState(s.state),
          tone: _mapTone(s.tone),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        QeranSectionHeader(
          title: LocaleKeys.matchmaker_cases_timeline_title.t(context),
        ),
        QeranSpacing.vs12,
        QeranStepper(
          steps: steps,
          currentLabel: LocaleKeys.matchmaker_cases_timeline_current.t(context),
        ),
      ],
    );
  }

  QeranStepState _mapState(CaseStepState s) => switch (s) {
        CaseStepState.done => QeranStepState.done,
        CaseStepState.current => QeranStepState.current,
        CaseStepState.future => QeranStepState.future,
      };

  QeranStepTone _mapTone(CaseStepTone t) => switch (t) {
        CaseStepTone.normal => QeranStepTone.normal,
        CaseStepTone.success => QeranStepTone.success,
        CaseStepTone.ended => QeranStepTone.ended,
      };
}

/// Inline success confirmation shown briefly after an update lands.
class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.gold40, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: QeranColors.gold,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 24,
              color: QeranColors.wine,
            ),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              LocaleKeys.matchmaker_cases_update_success.t(context),
              style: QeranTypography.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
