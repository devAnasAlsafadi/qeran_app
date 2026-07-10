import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../data/error_codes.dart';
import '../../domain/entities/formal_request_status.dart';
import '../../domain/usecases/update_formal_request_status_usecase.dart';
import 'matchmaker_case_status_state.dart';

/// Drives the server-validated formal-request status update for one case
/// ([formalRequestId]). A single in-flight slot guards double-submit; each
/// completed attempt bumps `eventVersion` so the screen reacts exactly once
/// (snackbar + pop). An `INVALID_STATUS_TRANSITION` is flagged so the screen
/// shows a local message and refreshes the list instead of the server's
/// numeric text.
class MatchmakerCaseStatusCubit extends Cubit<MatchmakerCaseStatusState> with SafeEmit<MatchmakerCaseStatusState> {
  final UpdateFormalRequestStatusUseCase _update;
  final int formalRequestId;

  MatchmakerCaseStatusCubit({
    required this.formalRequestId,
    required UpdateFormalRequestStatusUseCase update,
  })  : _update = update,
        super(const MatchmakerCaseStatusState());

  Future<void> submit(FormalRequestStatus target) async {
    if (state.isBusy) return; // guard double-submit
    emit(state.copyWith(
      inFlight: target,
      clearMessage: true,
      isInvalidTransition: false,
    ));
    final result = await _update(
      formalRequestId: formalRequestId,
      newStatus: target,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        final isInvalid = failure is CodedServerFailure &&
            failure.errorCode ==
                CompatibilityCasesErrorCodes.invalidStatusTransition;
        AppLogger.warning(
          'MATCHMAKER — case status update failed invalid=$isInvalid',
          tag: 'MATCHMAKER',
        );
        emit(state.copyWith(
          clearInFlight: true,
          outcome: CaseStatusOutcome.failure,
          eventVersion: state.eventVersion + 1,
          message: isInvalid
              ? LocaleKeys.matchmaker_cases_invalid_transition
              : failure.message,
          isInvalidTransition: isInvalid,
        ));
      },
      (message) => emit(state.copyWith(
        clearInFlight: true,
        outcome: CaseStatusOutcome.success,
        eventVersion: state.eventVersion + 1,
        message: message,
        isInvalidTransition: false,
      )),
    );
  }
}
