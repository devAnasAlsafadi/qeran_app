import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/affiliate_commissions_page.dart';
import '../repositories/affiliate_repository.dart';

/// Fetches one page of the matchmaker's commission ledger.
class GetAffiliateCommissionsUseCase {
  final AffiliateRepository _repository;
  const GetAffiliateCommissionsUseCase(this._repository);

  Future<Either<Failure, AffiliateCommissionsPage>> call({
    required int page,
    required int pageSize,
  }) =>
      _repository.getCommissions(page: page, pageSize: pageSize);
}
