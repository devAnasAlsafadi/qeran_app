import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../data/error_codes.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/usecases/submit_report_usecase.dart';
import 'report_state.dart';

/// Owns a single report submission. Classifies the failure on the backend
/// `errorCode` (never the message) into a localized outcome. Screen-scoped
/// (factory in DI) — one per report sheet.
class ReportCubit extends Cubit<ReportState> with SafeEmit<ReportState> {
  final SubmitReportUseCase _submitReport;

  ReportCubit({required SubmitReportUseCase submitReport})
      : _submitReport = submitReport,
        super(const ReportState());

  Future<void> submit({
    String? targetUserId,
    String? targetContentId,
    required ReportReason reason,
    String? note,
  }) async {
    if (state.submitting) return; // single in-flight guard
    emit(state.copyWith(submitting: true));

    final result = await _submitReport(
      targetUserId: targetUserId,
      targetContentId: targetContentId,
      reason: reason,
      note: note,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        final code = failure is CodedServerFailure ? failure.errorCode : null;
        final key = switch (code) {
          ReportErrorCodes.targetUserNotFound =>
            LocaleKeys.report_error_target_unavailable,
          ReportErrorCodes.validationError => LocaleKeys.report_error_validation,
          _ => LocaleKeys.errors_generic,
        };
        emit(state.copyWith(
          submitting: false,
          outcome: ReportOutcome.failure,
          eventVersion: state.eventVersion + 1,
          messageKey: key,
        ));
      },
      (_) => emit(state.copyWith(
        submitting: false,
        outcome: ReportOutcome.success,
        eventVersion: state.eventVersion + 1,
        messageKey: LocaleKeys.report_success,
      )),
    );
  }
}
