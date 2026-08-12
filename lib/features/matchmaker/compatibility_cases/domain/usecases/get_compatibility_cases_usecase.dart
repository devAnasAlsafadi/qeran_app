import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/compatibility_cases_page.dart';
import '../entities/matchmaker_cases_filter.dart';
import '../repositories/compatibility_cases_repository.dart';

class GetCompatibilityCasesUseCase {
  final CompatibilityCasesRepository _repository;
  const GetCompatibilityCasesUseCase(this._repository);

  Future<Either<Failure, CompatibilityCasesPage>> call({
    required int page,
    required int pageSize,
    MatchmakerCasesFilter filter = const MatchmakerCasesFilter(),
  }) => _repository.getCases(page: page, pageSize: pageSize, filter: filter);
}
