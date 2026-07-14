import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/affiliate_commissions_page.dart';
import '../entities/affiliate_summary.dart';

abstract interface class AffiliateRepository {
  /// Loads the affiliate dashboard header. A not-enrolled matchmaker (backend
  /// 404) resolves to `Left(AffiliateNotEnrolledFailure())`, distinct from a
  /// real error.
  Future<Either<Failure, AffiliateSummary>> getSummary();

  /// Loads one page of the commission ledger (1-indexed [page]).
  Future<Either<Failure, AffiliateCommissionsPage>> getCommissions({
    required int page,
    required int pageSize,
  });
}
