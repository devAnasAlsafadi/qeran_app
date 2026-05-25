import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/discovery_page.dart';
import '../repositories/discovery_repository.dart';

class FetchDiscoveryPageUseCase {
  final DiscoveryRepository _repository;

  const FetchDiscoveryPageUseCase(this._repository);

  Future<Either<Failure, DiscoveryPage>> call({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) {
    return _repository.fetchPage(
      page: page,
      pageSize: pageSize,
      filterParams: filterParams,
    );
  }
}
