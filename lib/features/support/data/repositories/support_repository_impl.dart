import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/support_category.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_datasource.dart';

class SupportRepositoryImpl with BaseRepository implements SupportRepository {
  final SupportRemoteDataSource _dataSource;

  const SupportRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<SupportCategory>>> getCategories() =>
      executeApiCall(() async {
        final models = await _dataSource.getCategories();
        return models.map((m) => m.toEntity()).toList(growable: false);
      });

  @override
  Future<Either<Failure, Unit>> createTicket({
    required int categoryId,
    required String subject,
    required String details,
  }) async {
    // Not via `executeApiCall`: that collapses every ServerException to a
    // plain ServerFailure, dropping the errorCode. We preserve it so the cubit
    // can recognise SUPPORT_TICKETS_LIMIT_REACHED and friends.
    try {
      await _dataSource.createTicket(
        categoryId: categoryId,
        subject: subject,
        details: details,
      );
      return const Right(unit);
    } on CodedServerException catch (e) {
      AppLogger.error('SUPPORT — create ticket failed', error: e, tag: 'REPO');
      return Left(CodedServerFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      AppLogger.error('SUPPORT — create ticket failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      AppLogger.error('SUPPORT — create ticket auth', error: e, tag: 'REPO');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('SUPPORT — create ticket crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
