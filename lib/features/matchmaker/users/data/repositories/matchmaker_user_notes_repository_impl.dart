import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/matchmaker_user_note.dart';
import '../../domain/repositories/matchmaker_user_notes_repository.dart';
import '../datasources/matchmaker_user_notes_remote_datasource.dart';

/// Not via `BaseRepository.executeApiCall`: that maps every ServerException to
/// a plain ServerFailure, dropping the errorCode. The notes UI must recognise
/// VALIDATION_ERROR / USER_NOT_FOUND / UNAUTHORIZED, so [_guard] preserves the
/// code as a [CodedServerFailure] (same approach as compatibility-cases).
class MatchmakerUserNotesRepositoryImpl
    implements MatchmakerUserNotesRepository {
  final MatchmakerUserNotesRemoteDataSource _dataSource;

  const MatchmakerUserNotesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerUserNote?>> getNote(String userId) =>
      _guard(() async => (await _dataSource.getNote(userId))?.toEntity());

  @override
  Future<Either<Failure, MatchmakerUserNote>> saveNote({
    required String userId,
    required String content,
  }) =>
      _guard(
        () async =>
            (await _dataSource.saveNote(userId: userId, content: content))
                .toEntity(),
      );

  @override
  Future<Either<Failure, Unit>> deleteNote(String userId) => _guard(() async {
        await _dataSource.deleteNote(userId);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on CodedServerException catch (e) {
      AppLogger.error('MATCHMAKER — note failed', error: e, tag: 'REPO');
      return Left(
        CodedServerFailure(message: e.message, errorCode: e.errorCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('MATCHMAKER — note failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      AppLogger.error('MATCHMAKER — note auth', error: e, tag: 'REPO');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('MATCHMAKER — note crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
