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
    } catch (e) {
      return Left(_failureOf(e));
    }
  }
}

/// What a call threw, as the failure the cubits branch on — logged.
Failure _failureOf(Object e) {
  if (e is DailyViewsExceededException) {
    // Typed daily-view cap — must map before the generic ServerException
    // (it's a subtype) so the resetAt survives to the cubit.
    AppLogger.info('Daily views exceeded', tag: 'REPO');
    return DailyViewsExceededFailure(resetAt: e.resetAt);
  }
  if (e is OfflineException) {
    AppLogger.warning('Offline request', tag: 'REPO');
    return const OfflineFailure();
  }
  if (e is UploadCancelledException) {
    AppLogger.info('Upload cancelled', tag: 'REPO');
    return const UploadCancelledFailure();
  }
  return _serverFailureOf(e);
}

Failure _serverFailureOf(Object e) {
  if (e is CodedServerException) {
    // The backend commonly reports business failures inside an HTTP 200
    // envelope. Preserve its machine-readable code so feature cubits can
    // distinguish e.g. UNAUTHORIZED from a generic server failure.
    AppLogger.error('Coded server error', error: e, tag: 'REPO');
    return CodedServerFailure(
      message: e.message,
      errorCode: e.errorCode,
      statusCode: e.statusCode,
      data: e.data,
    );
  }
  if (e is ServerException) {
    AppLogger.error('Server error', error: e, tag: 'REPO');
    return ServerFailure(message: e.message);
  }
  if (e is AuthException) {
    AppLogger.error('Auth error', error: e, tag: 'REPO');
    return AuthFailure(message: e.message);
  }
  AppLogger.error('Unexpected error', error: e, tag: 'REPO');
  return ServerFailure(message: LocaleKeys.errors_unexpected);
}
