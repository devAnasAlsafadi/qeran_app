import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/blocked_user.dart';
import '../../domain/repositories/block_repository.dart';
import '../datasources/block_remote_datasource.dart';

class BlockRepositoryImpl implements BlockRepository {
  final BlockRemoteDataSource _dataSource;

  const BlockRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Unit>> blockUser(String targetUserId) =>
      _guarded(() async {
        await _dataSource.blockUser(targetUserId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> unblockUser(String targetUserId) =>
      _guarded(() async {
        await _dataSource.unblockUser(targetUserId);
        return unit;
      });

  @override
  Future<Either<Failure, List<BlockedUser>>> getBlockedUsers() =>
      _guarded(() async {
        final models = await _dataSource.getBlockedUsers();
        return models.map((m) => m.toEntity()).toList(growable: false);
      });

  /// Preserves the backend `errorCode` (via [CodedServerFailure]) so the cubits
  /// can classify `TARGET_USER_NOT_FOUND` neutrally — per-datasource, never a
  /// central status guard.
  Future<Either<Failure, T>> _guarded<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on OfflineException {
      return const Left(OfflineFailure());
    } on CodedServerException catch (e) {
      AppLogger.error('BLOCK — failed (${e.errorCode})', error: e, tag: 'REPO');
      return Left(
        CodedServerFailure(message: e.message, errorCode: e.errorCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('BLOCK — failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('BLOCK — crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
