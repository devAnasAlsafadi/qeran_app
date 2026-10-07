import 'package:qeran/generated/locale_keys.g.dart';

class ServerException implements Exception {
  final String message;

  /// HTTP status code of the failing response, when the network layer had one
  /// (currently set only by the raw non-2xx path in `HttpConsumer`). Optional
  /// and defaults to null, so every existing throw site keeps working; callers
  /// that need to branch on transport status (e.g. 404 = not-enrolled) read it.
  final int? statusCode;
  ServerException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

/// Thrown by the network layer when the device is offline — either caught
/// pre-flight (no active transport reported by `ConnectivityService`) or
/// mapped from a transport-level `SocketException` / connection-failure
/// `ClientException`. **Standalone** (NOT a `ServerException`) so the typed
/// `on ServerException` classifiers in data sources never intercept it; it
/// bubbles straight to `BaseRepository.executeApiCall`, which maps it to
/// `OfflineFailure`.
class OfflineException implements Exception {
  final String message;
  const OfflineException({this.message = LocaleKeys.errors_offline});

  @override
  String toString() => message;
}

/// Thrown by an upload once its `UploadCancel` fired: she stopped it
/// herself. Standalone like [OfflineException], so it reaches
/// `BaseRepository.executeApiCall` as itself and maps to
/// `UploadCancelledFailure`.
class UploadCancelledException implements Exception {
  const UploadCancelledException();
}

/// `ServerException` enriched with a machine-readable `errorCode` from
/// the backend envelope (e.g. `SUBSCRIPTION_REQUIRED`, `LIKE_EXPIRED`).
/// Data-source classifiers prefer this over Arabic message matching.
/// Existing `on ServerException` catch sites keep working — this is a
/// subtype, not a replacement.
class CodedServerException extends ServerException {
  final String? errorCode;

  /// The envelope's `data` on an error, when the body had one — e.g.
  /// `{ retryAfterSeconds }` on a `RATE_LIMITED` or `OTP_COOLDOWN` answer.
  final Object? data;
  CodedServerException({
    required super.message,
    required this.errorCode,
    super.statusCode,
    this.data,
  });
}

/// Thrown by the discovery feed fetch when the backend returns
/// `DAILY_VIEWS_EXCEEDED` — the no-subscription daily view cap. Carries the
/// [resetAt] instant (next UTC midnight) so the UI can show a live countdown.
/// A "come back tomorrow" signal, NOT a paywall. Subtype of [ServerException]
/// so existing `on ServerException` sites still catch it as a fallback.
class DailyViewsExceededException extends ServerException {
  final DateTime resetAt;
  DailyViewsExceededException({
    required this.resetAt,
    super.message = LocaleKeys.errors_generic,
  });
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException({required this.message});

  @override
  String toString() => message;
}
