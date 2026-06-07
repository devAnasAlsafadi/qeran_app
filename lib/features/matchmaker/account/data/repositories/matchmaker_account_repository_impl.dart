import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/matchmaker_me.dart';
import '../../domain/entities/matchmaker_me_image.dart';
import '../../domain/repositories/matchmaker_account_repository.dart';
import '../datasources/matchmaker_account_remote_datasource.dart';

/// Not via `BaseRepository.executeApiCall`: that maps every ServerException to
/// a plain ServerFailure, dropping the errorCode. The account UI must recognise
/// VALIDATION_ERROR / USER_NOT_FOUND, so [_guard] preserves the code as a
/// [CodedServerFailure] (same approach as the notes / compatibility-cases repos).
class MatchmakerAccountRepositoryImpl implements MatchmakerAccountRepository {
  final MatchmakerAccountRemoteDataSource _dataSource;

  const MatchmakerAccountRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerMe>> getMe() =>
      _guard(() async => (await _dataSource.getMe()).toEntity());

  @override
  Future<Either<Failure, Unit>> updateName(String name) => _guard(() async {
        await _dataSource.updateName(name);
        return unit;
      });

  @override
  Future<Either<Failure, MatchmakerMeImage>> uploadPhoto(File image) =>
      _guard(() async => (await _dataSource.uploadPhoto(image)).toEntity());

  @override
  Future<Either<Failure, Unit>> deactivate() => _guard(() async {
        await _dataSource.deactivate();
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on CodedServerException catch (e) {
      AppLogger.error('MATCHMAKER — account failed', error: e, tag: 'REPO');
      return Left(
        CodedServerFailure(message: e.message, errorCode: e.errorCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('MATCHMAKER — account failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      AppLogger.error('MATCHMAKER — account auth', error: e, tag: 'REPO');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('MATCHMAKER — account crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
