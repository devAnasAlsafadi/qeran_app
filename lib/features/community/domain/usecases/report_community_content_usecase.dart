import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/domain/repositories/content_reporter.dart';

import '../repositories/community_repository.dart';

/// A report on a post, comment or reply, through Community (Q3) — what the
/// report sheet sends for content.
class ReportCommunityContentUseCase implements ContentReporter {
  final CommunityRepository _repository;
  const ReportCommunityContentUseCase(this._repository);

  @override
  Future<Either<Failure, void>> report(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  }) => _repository.reportContent(target, reason: reason, note: note);
}
