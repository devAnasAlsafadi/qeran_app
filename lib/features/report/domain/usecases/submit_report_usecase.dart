import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/report_reason.dart';
import '../repositories/report_repository.dart';

/// Submits a UGC report (`POST /api/reports`). Thin pass-through to the
/// repository — one instance per call site via the cubit.
class SubmitReportUseCase {
  final ReportRepository _repository;

  const SubmitReportUseCase(this._repository);

  Future<Either<Failure, String>> call({
    String? targetUserId,
    String? targetContentId,
    required ReportReason reason,
    String? note,
  }) =>
      _repository.submitReport(
        targetUserId: targetUserId,
        targetContentId: targetContentId,
        reason: reason,
        note: note,
      );
}
