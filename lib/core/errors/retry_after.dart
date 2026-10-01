import 'errors.dart';

/// The server's wait on a throttled answer — `data.retryAfterSeconds` on a
/// coded failure (Community's `RATE_LIMITED`, auth's `OTP_COOLDOWN`). Null
/// when it sent none, or nothing usable, so callers fall back to their own
/// short wait.
Duration? retryAfterOf(Failure failure) {
  if (failure is! CodedServerFailure) return null;
  final data = failure.data;
  if (data is! Map) return null;
  final seconds = switch (data['retryAfterSeconds']) {
    final num n => n.ceil(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };
  return (seconds == null || seconds <= 0) ? null : Duration(seconds: seconds);
}
