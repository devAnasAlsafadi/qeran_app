import 'package:qeran/core/app_logger.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'exceptions.dart';

/// Matches a translation key (`errors.timeout`) and nothing a backend would
/// ever send as prose — every segment is ASCII word chars and there is at
/// least one dot. Arabic/English sentences never match.
///
/// Single source of truth: `LocalizationExtension.tOrRaw` reads this too, so
/// the UI safety net and the data-layer classifier can never drift apart.
final RegExp kLocaleKeyShape = RegExp(r'^[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+$');

/// Maps a failed request onto a locale KEY — never the server's own prose.
///
/// The repository flattens every [ServerException] into
/// `ServerFailure(message)` and the `errorCode` is lost after that point, so
/// classification has to happen inside the data source. What leaves a
/// classified call is therefore always a key the UI can translate.
///
/// [codeKeys] is the caller's own `errorCode` → locale-key map (each feature
/// passes its own). Resolution order:
///
/// 1. a known `errorCode` → its specific key;
/// 2. otherwise the transport key `HttpConsumer` already produced
///    (`errors.timeout`, `errors.server`, …) when the message *is* a key;
/// 3. otherwise [LocaleKeys.errors_generic].
///
/// The server's prose is logged for diagnosis and never returned. A missing
/// or unrecognised code costs specificity, never correctness.
String serverFailureKey(
  ServerException exception, {
  required Map<String, String> codeKeys,
  String label = 'REQUEST',
  String tag = 'API',
}) {
  final code = exception is CodedServerException ? exception.errorCode : null;
  final key = codeKeys[code] ?? _transportKeyOrGeneric(exception.message);
  AppLogger.warning(
    '$label failed — errorCode="${code ?? '-'}" key=$key '
    'serverMessage="${exception.message}"',
    tag: tag,
  );
  return key;
}

/// `HttpConsumer` already emits locale keys for transport failures, so keep
/// those; a raw server sentence becomes `errors.generic`.
String _transportKeyOrGeneric(String message) =>
    kLocaleKeyShape.hasMatch(message.trim())
    ? message.trim()
    : LocaleKeys.errors_generic;
