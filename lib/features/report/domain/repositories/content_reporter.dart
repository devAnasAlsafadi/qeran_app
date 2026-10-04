import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/report_reason.dart';
import '../entities/report_target.dart';

/// Sends a report on a post, comment or reply. Community provides it (Q3):
/// its content goes through Community's datasource, so the dev-flag mock's
/// made-up ids can never reach the real `POST reports`.
abstract interface class ContentReporter {
  Future<Either<Failure, void>> report(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  });
}
