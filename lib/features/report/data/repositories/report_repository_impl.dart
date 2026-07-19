import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/report_reason.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

class ReportRepositoryImpl with BaseRepository implements ReportRepository {
  final ReportRemoteDataSource _dataSource;

  const ReportRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, String>> submitReport({
    String? targetUserId,
    String? targetContentId,
    required ReportReason reason,
    String? note,
  }) async {
    // Not via executeApiCall: that collapses every ServerException to a plain
    // ServerFailure, dropping the errorCode. We preserve it so the cubit can
    // recognise VALIDATION_ERROR / TARGET_USER_NOT_FOUND (per-datasource,
    // Bucket A — never a central status guard).
    try {
      final reportId = await _dataSource.submitReport(
        targetUserId: targetUserId,
        targetContentId: targetContentId,
        reason: reason,
        note: note,
      );
      return Right(reportId);
    } on OfflineException {
      return const Left(OfflineFailure());
    } on CodedServerException catch (e) {
      AppLogger.error('REPORT — submit failed', error: e, tag: 'REPO');
      return Left(
        CodedServerFailure(message: e.message, errorCode: e.errorCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('REPORT — submit failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('REPORT — submit crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
