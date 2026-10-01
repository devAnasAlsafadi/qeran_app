import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_logger.dart';
import '../errors/exceptions.dart';
import 'http_errors.dart';

/// Enveloped responses (`{ status, message, errorCode, data }`): returns the
/// envelope on a 2xx with `status == 1`; throws otherwise, keeping the
/// optional `errorCode` so data-source classifiers can switch on it instead
/// of substring-matching the Arabic message.
dynamic handleEnvelopedResponse(http.Response response) {
  AppLogger.debug(
    '${response.statusCode} ${response.request?.url}',
    tag: 'HTTP',
  );
  try {
    final dynamic responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody['status'] == 1 || responseBody['status'] == true) {
        return responseBody;
      } else {
        // Status-envelope failure on a 2xx response.
        throw CodedServerException(
          message: responseBody['message'] ?? "Operation Failed",
          errorCode: responseBody is Map ? responseBody['errorCode'] as String? : null,
          data: responseBody is Map ? responseBody['data'] : null,
        );
      }
    } else {
      String errorMessage = statusErrorMessage(response.statusCode);
      if (responseBody is Map) {
        if (responseBody['errors'] != null && responseBody['errors'] is Map) {
          final Map<String, dynamic> errors = Map<String, dynamic>.from(
            responseBody['errors'],
          );
          if (errors.isNotEmpty) {
            final firstList = errors.values.first;
            if (firstList is List && firstList.isNotEmpty) {
              errorMessage = firstList.first.toString();
            }
          }
        } else {
          errorMessage =
              responseBody['message'] as String? ??
              responseBody['error'] as String? ??
              statusErrorMessage(response.statusCode);
        }
      }
      AppLogger.error(
        '${response.statusCode} ${response.request?.url}: $errorMessage',
        tag: 'HTTP',
      );
      throw CodedServerException(
        message: errorMessage,
        errorCode: responseBody is Map ? responseBody['errorCode'] as String? : null,
        data: responseBody is Map ? responseBody['data'] : null,
      );
    }
  } catch (e) {
    if (e is OfflineException) rethrow;
    if (isOfflineTransportError(e)) throw const OfflineException();
    if (e is ServerException) rethrow;
    AppLogger.error(
      '${response.statusCode} non-JSON body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      tag: 'HTTP',
    );
    throw ServerException(message: statusErrorMessage(response.statusCode));
  }
}

/// Same status-code handling as [handleEnvelopedResponse] but does **not**
/// enforce the `status == 1` envelope. Used by `getRaw` / `postRaw` for
/// endpoints that return a raw List, a literal `null`, or a Map with a
/// different success-flag shape (e.g. the subscriptions endpoints'
/// `success: true/false`).
///
/// * 2xx → the decoded body as-is, **except** a Map with `success: false`
///   (the `/subscribe` envelope), which throws with its `message`.
/// * non-2xx → throws with the parsed message and the transport status.
dynamic handleRawResponse(http.Response response) {
  AppLogger.debug(
    '${response.statusCode} (raw) ${response.request?.url}',
    tag: 'HTTP',
  );
  final ok = response.statusCode >= 200 && response.statusCode < 300;

  // ── Non-2xx: throw WITH the transport status before any parse, so a status
  // (e.g. 404) is never lost to an empty / non-JSON error body. Enrich the
  // message + errorCode from the body only when it actually parses as JSON.
  if (!ok) {
    dynamic body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      body = null; // empty / non-JSON error body — status still carried below
    }
    var errorMessage = statusErrorMessage(response.statusCode);
    String? errorCode;
    Object? data;
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstList = errors.values.first;
        if (firstList is List && firstList.isNotEmpty) {
          errorMessage = firstList.first.toString();
        }
      } else {
        errorMessage = body['message'] as String? ??
            body['error'] as String? ??
            errorMessage;
      }
      errorCode = body['errorCode'] as String?;
      data = body['data'];
    }
    AppLogger.error(
      '${response.statusCode} (raw) ${response.request?.url}: $errorMessage',
      tag: 'HTTP',
    );
    throw CodedServerException(
      message: errorMessage,
      errorCode: errorCode,
      // Preserve the transport status so raw callers can branch on it
      // (e.g. affiliate maps 404 → not-enrolled).
      statusCode: response.statusCode,
      data: data,
    );
  }

  // ── 2xx success path ──
  // Server may return literal `null` (e.g. `/subscriptions/current`
  // when not subscribed) — keep that as a valid 2xx response.
  if (response.body.isEmpty) return null;

  dynamic body;
  try {
    body = jsonDecode(response.body);
  } catch (_) {
    AppLogger.error(
      '${response.statusCode} non-JSON body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      tag: 'HTTP',
    );
    throw ServerException(message: statusErrorMessage(response.statusCode));
  }

  if (body is Map<String, dynamic> && body['success'] == false) {
    throw CodedServerException(
      message: body['message'] as String? ?? 'Operation Failed',
      errorCode: body['errorCode'] as String?,
      data: body['data'],
    );
  }
  // `status: 0` envelopes are NOT thrown here — data sources that
  // use `postRaw` inspect the body themselves and classify before
  // bubbling up (see `LikesRemoteDataSourceImpl._action` and the
  // matches data source). Throwing here would short-circuit that.
  return body;
}
