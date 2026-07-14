import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/affiliate_summary.dart';
import '../repositories/affiliate_repository.dart';

/// Loads the matchmaker's affiliate summary (dashboard header).
class GetAffiliateSummaryUseCase {
  final AffiliateRepository _repository;
  const GetAffiliateSummaryUseCase(this._repository);

  Future<Either<Failure, AffiliateSummary>> call() => _repository.getSummary();
}
