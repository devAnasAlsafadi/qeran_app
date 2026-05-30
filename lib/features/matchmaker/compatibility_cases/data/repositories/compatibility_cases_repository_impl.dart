import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/compatibility_cases_page.dart';
import '../../domain/entities/formal_request_status.dart';
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

  @override
  Future<Either<Failure, String>> updateFormalRequestStatus({
    required int formalRequestId,
    required FormalRequestStatus newStatus,
  }) async {
    final wire = newStatus.apiValue;
    if (wire == null) {
      // `unknown` has no wire value — never offered as a target by the UI.
      return const Left(ServerFailure(message: LocaleKeys.errors_generic));
    }
    // Not via `executeApiCall`: that maps every ServerException to a plain
    // ServerFailure, dropping the errorCode. We need the code preserved so
    // the cubit can recognise INVALID_STATUS_TRANSITION.
    try {
      final message = await _dataSource.updateStatus(
        formalRequestId: formalRequestId,
        newStatus: wire,
      );
      return Right(message);
    } on CodedServerException catch (e) {
      AppLogger.error('MATCHMAKER — update status failed', error: e, tag: 'REPO');
      return Left(CodedServerFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      AppLogger.error('MATCHMAKER — update status failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      AppLogger.error('MATCHMAKER — update status auth', error: e, tag: 'REPO');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('MATCHMAKER — update status crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
