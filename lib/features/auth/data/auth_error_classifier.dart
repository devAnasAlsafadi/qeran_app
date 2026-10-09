import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/server_error_classifier.dart';

/// An auth endpoint's failure, its message turned into a locale KEY before it
/// leaves the data source: the server's prose is English, and `.t()` would
/// render it verbatim.
///
/// A coded failure stays coded. Its `errorCode` and `data` travel on, so
/// `BaseRepository` hands them up as a `CodedServerFailure` and the bloc can
/// read `OTP_COOLDOWN`'s `retryAfterSeconds` (Phase 4 B2).
ServerException classifyAuthFailure(
  ServerException e, {
  required Map<String, String> codeKeys,
  required String label,
}) {
  final key = serverFailureKey(
    e,
    codeKeys: codeKeys,
    label: label,
    tag: 'AUTH',
  );
  return switch (e) {
    CodedServerException() => CodedServerException(
      message: key,
      errorCode: e.errorCode,
      statusCode: e.statusCode,
      data: e.data,
    ),
    _ => ServerException(message: key),
  };
}
