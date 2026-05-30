import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
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

/// Case detail (M3b). Receives the already-loaded [CompatibilityCase] (the
/// list payload is the whole truth — there's no detail endpoint), shows both
/// participants + every status signal, and drives the server-validated
/// formal-request status update. A successful update — or an
/// `INVALID_STATUS_TRANSITION` (the case may have moved / closed) — pops back
/// with `true` so the list refreshes.
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

class _CaseDetailView extends StatelessWidget {
  const _CaseDetailView({required this.caseItem});

  final CompatibilityCase caseItem;

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
                CaseParticipantsPair(
                  myUser: caseItem.myUser,
                  otherUser: caseItem.otherUser,
                  avatarSize: 72,
                  showRoleLabels: true,
                ),
                QeranSpacing.vs24,
                CaseStatusSection(caseItem: caseItem),
                QeranSpacing.vs16,
                CaseStatusActions(caseItem: caseItem),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onOutcome(BuildContext context, MatchmakerCaseStatusState state) {
    switch (state.outcome) {
      case CaseStatusOutcome.success:
        // The server's `data` text is already human-readable Arabic — use it
        // directly, falling back to a local key only when empty.
        final raw = state.message;
        final msg = (raw == null || raw.isEmpty)
            ? LocaleKeys.matchmaker_cases_update_success.t(context)
            : raw;
        AppSnackBar.showOnRoot(message: msg, type: SnackBarType.success);
        NavigationManager.pop(context, true);
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
