import 'package:dartz/dartz.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

typedef ApiCall<T> = Future<T> Function();

mixin BaseRepository {
  Future<Either<Failure, T>> executeApiCall<T>(ApiCall<T> apiCall) async {
    try {
      final result = await apiCall();
      return Right(result);
    } on DailyViewsExceededException catch (e) {
      // Typed daily-view cap — must map before the generic ServerException
      // catch (it's a subtype) so the resetAt survives to the cubit.
      AppLogger.info('Daily views exceeded', tag: 'REPO');
      return Left(DailyViewsExceededFailure(resetAt: e.resetAt));
    } on OfflineException {
      AppLogger.warning('Offline request', tag: 'REPO');
      return const Left(OfflineFailure());
    } on ServerException catch (e) {
      AppLogger.error('Server error', error: e, tag: 'REPO');
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      AppLogger.error('Auth error', error: e, tag: 'REPO');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error', error: e, tag: 'REPO');
      return Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }
}
