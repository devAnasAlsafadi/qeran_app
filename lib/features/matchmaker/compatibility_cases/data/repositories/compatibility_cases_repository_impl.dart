import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/compatibility_cases_page.dart';
import '../../domain/repositories/compatibility_cases_repository.dart';
import '../datasources/compatibility_cases_remote_datasource.dart';

class CompatibilityCasesRepositoryImpl
    with BaseRepository
    implements CompatibilityCasesRepository {
  final CompatibilityCasesRemoteDataSource _dataSource;

  const CompatibilityCasesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, CompatibilityCasesPage>> getCases({
    required int page,
    required int pageSize,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getCases(page: page, pageSize: pageSize);
      return model.toEntity();
    });
  }
}
