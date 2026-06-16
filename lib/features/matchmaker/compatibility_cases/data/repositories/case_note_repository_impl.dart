import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/case_note.dart';
import '../../domain/repositories/case_note_repository.dart';
import '../datasources/case_note_remote_datasource.dart';

/// Not via `BaseRepository.executeApiCall`: that maps every ServerException to
/// a plain ServerFailure, dropping the errorCode. The notes UI must recognise
/// VALIDATION_ERROR / CASE_NOT_FOUND / NOT_INVOLVED_IN_CASE / UNAUTHORIZED, so
/// [_guard] preserves the code as a [CodedServerFailure] (same approach as the
/// user-notes repository).
class CaseNoteRepositoryImpl implements CaseNoteRepository {
  final CaseNoteRemoteDataSource _dataSource;

  const CaseNoteRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, CaseNote?>> getNote(int caseId) =>
      _guard(() async => (await _dataSource.getNote(caseId))?.toEntity());

  @override
  Future<Either<Failure, CaseNote>> saveNote({
    required int caseId,
    required String content,
  }) =>
      _guard(
        () async =>
            (await _dataSource.saveNote(caseId: caseId, content: content))
                .toEntity(),
      );

  @override
  Future<Either<Failure, Unit>> deleteNote(int caseId) => _guard(() async {
        await _dataSource.deleteNote(caseId);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on CodedServerException catch (e) {
      AppLogger.error('MATCHMAKER — case note failed', error: e, tag: 'REPO');
      return Left(
        CodedServerFailure(message: e.message, errorCode: e.errorCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('MATCHMAKER — case note failed', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      AppLogger.error('MATCHMAKER — case note auth', error: e, tag: 'REPO');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('MATCHMAKER — case note crashed', error: e, tag: 'REPO');
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
