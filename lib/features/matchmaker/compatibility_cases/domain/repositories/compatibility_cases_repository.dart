import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/compatibility_cases_page.dart';
import '../entities/formal_request_status.dart';

abstract interface class CompatibilityCasesRepository {
  /// Fetches one page of compatibility cases. Left on transport / auth
  /// failure, Right with the parsed page on success.
  Future<Either<Failure, CompatibilityCasesPage>> getCases({
    required int page,
    required int pageSize,
  });

  /// Updates a case's formal-request status (server-validated). Right with
  /// the success message on success; Left on failure — an
  /// `INVALID_STATUS_TRANSITION` surfaces as a [CodedServerFailure] carrying
  /// that code so the cubit can special-case it.
  Future<Either<Failure, String>> updateFormalRequestStatus({
    required int formalRequestId,
    required FormalRequestStatus newStatus,
  });
}
