import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../data/error_codes.dart';
import '../../domain/entities/report_reason.dart';
import 'report_state.dart';

/// Sends one report — the reason chosen and the member's note — to where its
/// target belongs: a profile through the report feature, Community content
/// through Community (Q3). DI picks it from the target.
typedef ReportCall =
    Future<Either<Failure, void>> Function(ReportReason reason, String? note);

/// Owns a single report submission. Classifies the failure on the backend
/// `errorCode` (never the message) into a localized outcome. Screen-scoped
/// (factory in DI) — one per report sheet.
class ReportCubit extends Cubit<ReportState> with SafeEmit<ReportState> {
  final ReportCall _send;

  ReportCubit({required ReportCall send})
    : _send = send,
      super(const ReportState());

  Future<void> submit({required ReportReason reason, String? note}) async {
    if (state.submitting) return; // single in-flight guard
    emit(state.copyWith(submitting: true));

    final result = await _send(reason, note);
    if (isClosed) return;

    result.fold(
      _onFailure,
      (_) => _settle(ReportOutcome.success, LocaleKeys.report_success),
    );
  }

  /// Content that's gone has nothing left to report (E7); anything else is
  /// a failure the member can try again from.
  void _onFailure(Failure failure) {
    final code = failure is CodedServerFailure ? failure.errorCode : null;
    switch (code) {
      case ReportErrorCodes.targetContentNotFound:
        _settle(ReportOutcome.gone, LocaleKeys.report_content_gone);
      case ReportErrorCodes.targetUserNotFound:
        _settle(
          ReportOutcome.failure,
          LocaleKeys.report_error_target_unavailable,
        );
      case ReportErrorCodes.validationError:
        _settle(ReportOutcome.failure, LocaleKeys.report_error_validation);
      default:
        _settle(ReportOutcome.failure, LocaleKeys.errors_generic);
    }
  }

  void _settle(ReportOutcome outcome, String messageKey) => emit(
    state.copyWith(
      submitting: false,
      outcome: outcome,
      eventVersion: state.eventVersion + 1,
      messageKey: messageKey,
    ),
  );
}
