import 'exceptions.dart';
import 'server_error_classifier.dart';

/// [e] with its message made a locale KEY ([serverFailureKey]) before it
/// leaves a data source. The HTTP layer puts the server's own sentence in the
/// message, and `.t()` prints a sentence verbatim — often English in the
/// Arabic UI (Phase 4 B4).
///
/// A coded failure stays coded: its `errorCode`, `statusCode` and `data`
/// travel on, so a cubit can still branch on the code. A typed subclass a
/// caller needs (e.g. `DailyViewsExceededException`) must be caught and
/// rethrown BEFORE this, or it comes back as a plain exception.
ServerException keyedServerException(
  ServerException e, {
  Map<String, String> codeKeys = const {},
  String label = 'REQUEST',
  String tag = 'API',
}) {
  final key = serverFailureKey(e, codeKeys: codeKeys, label: label, tag: tag);
  return switch (e) {
    CodedServerException() => CodedServerException(
      message: key,
      errorCode: e.errorCode,
      statusCode: e.statusCode,
      data: e.data,
    ),
    _ => ServerException(message: key, statusCode: e.statusCode),
  };
}
