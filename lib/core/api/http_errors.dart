import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:qeran/generated/locale_keys.g.dart';

/// Reactive offline classifier — true for a dropped/unreachable network
/// surfacing as a `SocketException` or a connection-failure `ClientException`
/// (covers the "on Wi-Fi but no real uplink" case the pre-flight can't see).
bool isOfflineTransportError(Object e) {
  if (e is SocketException) return true;
  if (e is http.ClientException) {
    final m = e.message.toLowerCase();
    return m.contains('failed host lookup') ||
        m.contains('connection refused') ||
        m.contains('connection closed') ||
        m.contains('connection reset') ||
        m.contains('connection failed') ||
        m.contains('network is unreachable') ||
        m.contains('software caused connection abort');
  }
  return false;
}

/// The message for a request that failed before any response arrived.
String transportErrorMessage(Object e) {
  if (e is TimeoutException) return LocaleKeys.errors_timeout;
  return LocaleKeys.errors_generic;
}

/// The message for a failing HTTP status when the body gives none.
String statusErrorMessage(int statusCode) => switch (statusCode) {
      400 => LocaleKeys.errors_bad_request,
      401 => LocaleKeys.errors_unauthorized,
      403 => LocaleKeys.errors_forbidden,
      404 => LocaleKeys.errors_not_found,
      408 => LocaleKeys.errors_timeout,
      429 => LocaleKeys.errors_too_many_requests,
      500 || 502 || 503 => LocaleKeys.errors_server,
      _ => LocaleKeys.errors_generic,
    };
