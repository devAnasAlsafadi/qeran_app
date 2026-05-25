class ServerException implements Exception {
  final String message;
  ServerException({required this.message});

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
  CodedServerException({required super.message, required this.errorCode});
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
