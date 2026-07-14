import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/affiliate_summary.dart';

abstract interface class AffiliateRepository {
  /// Loads the affiliate dashboard header. A not-enrolled matchmaker (backend
  /// 404) resolves to `Left(AffiliateNotEnrolledFailure())`, distinct from a
  /// real error.
  Future<Either<Failure, AffiliateSummary>> getSummary();
}
