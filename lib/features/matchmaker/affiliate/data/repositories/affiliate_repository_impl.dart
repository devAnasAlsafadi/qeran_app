import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/affiliate_summary.dart';
import '../../domain/failures/affiliate_failures.dart';
import '../../domain/repositories/affiliate_repository.dart';
import '../datasources/affiliate_remote_datasource.dart';

/// Not via `BaseRepository.executeApiCall`: the affiliate endpoints answer a
/// 404 when the matchmaker isn't enrolled, and that must become a distinct
/// [AffiliateNotEnrolledFailure] (dedicated UI state), not a generic error. The
/// raw HTTP path preserves the transport status on [CodedServerException], so
/// [_guard] branches on `statusCode == 404`.
class AffiliateRepositoryImpl implements AffiliateRepository {
  final AffiliateRemoteDataSource _dataSource;

  const AffiliateRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, AffiliateSummary>> getSummary() =>
      _guard(() async => (await _dataSource.getSummary()).toEntity());

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on CodedServerException catch (e) {
      // 404 = not enrolled in the affiliate program (distinct, dedicated state).
      if (e.statusCode == 404) {
        AppLogger.info('AFFILIATE — not enrolled (404)', tag: 'REPO');
        return const Left(AffiliateNotEnrolledFailure());
      }
      AppLogger.error('AFFILIATE — summary failed', error: e, tag: 'REPO');
      return Left(CodedServerFailure(
        message: e.message,
        errorCode: e.errorCode,
        statusCode: e.statusCode,
      ));
    } on OfflineException {
      AppLogger.warning('AFFILIATE — offline', tag: 'REPO');
      return const Left(OfflineFailure());
    } on ServerException catch (e) {
      AppLogger.error('AFFILIATE — summary failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      AppLogger.error('AFFILIATE — summary crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
