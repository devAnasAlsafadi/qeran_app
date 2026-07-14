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

/// `ServerException` enriched with a machine-readable `errorCode` from
/// the backend envelope (e.g. `SUBSCRIPTION_REQUIRED`, `LIKE_EXPIRED`).
/// Data-source classifiers prefer this over Arabic message matching.
/// Existing `on ServerException` catch sites keep working — this is a
/// subtype, not a replacement.
class CodedServerException extends ServerException {
  final String? errorCode;
  CodedServerException({
    required super.message,
    required this.errorCode,
    super.statusCode,
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
