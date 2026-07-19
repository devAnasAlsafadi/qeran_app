import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/report_reason.dart';

abstract interface class ReportRepository {
  /// `POST /api/reports`. At least one of [targetUserId] / [targetContentId]
  /// must be supplied. Returns the created reportId on success. On a status:0
  /// rejection returns a [CodedServerFailure] carrying the backend `errorCode`
  /// (`VALIDATION_ERROR` | `TARGET_USER_NOT_FOUND`) so the cubit can classify.
  Future<Either<Failure, String>> submitReport({
    String? targetUserId,
    String? targetContentId,
    required ReportReason reason,
    String? note,
  });
}
