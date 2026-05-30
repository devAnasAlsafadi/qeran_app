import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/compatibility_cases_page.dart';

abstract interface class CompatibilityCasesRepository {
  /// Fetches one page of compatibility cases. Left on transport / auth
  /// failure, Right with the parsed page on success.
  Future<Either<Failure, CompatibilityCasesPage>> getCases({
    required int page,
    required int pageSize,
  });
}
