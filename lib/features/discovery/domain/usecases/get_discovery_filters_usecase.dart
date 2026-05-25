import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/discovery_filter_question.dart';
import '../repositories/discovery_repository.dart';

class GetDiscoveryFiltersUseCase {
  final DiscoveryRepository _repository;

  const GetDiscoveryFiltersUseCase(this._repository);

  Future<Either<Failure, List<DiscoveryFilterQuestion>>> call() {
    return _repository.getFilters();
  }
}
