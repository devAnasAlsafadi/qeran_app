import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';

typedef ApiCall<T> = Future<T> Function();

mixin BaseRepository {
  Future<Either<Failure, T>> executeApiCall<T>(ApiCall<T> apiCall) async {
    try {
      final result = await apiCall();
      return Right(result);
    } on ServerException catch (e) {
      AppLogger.error('Server error', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      AppLogger.error('Auth error', error: e, tag: 'REPO');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error', error: e, tag: 'REPO');
      return Left(ServerFailure(message: 'حدث خطأ غير متوقع'));
    }
  }
}
