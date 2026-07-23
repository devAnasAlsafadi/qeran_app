import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../app_logger.dart';
import '../errors/exceptions.dart';
import '../services/connectivity_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import 'api_consumer.dart';
import 'end_points.dart';

class HttpConsumer extends ApiConsumer {
  final http.Client client;
  final StorageService storage;
  final LanguageService languageService;
  final ConnectivityService connectivity;

  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _multipartTimeout = Duration(seconds: 60);

  HttpConsumer({
    required this.client,
    required this.storage,
    required this.languageService,
    required this.connectivity,
  });

  /// Offline pre-flight — throws [OfflineException] BEFORE a request fires
  /// when the device reports no connectivity, so callers fast-fail instead of
  /// waiting out the 30s timeout. Placed at the top of each verb's `try` so a
  /// thrown [OfflineException] is rethrown by that verb's catch and bubbles to
  /// the repository as `OfflineFailure`.
  Future<void> _ensureOnline() async {
    if (!await connectivity.isOnline) throw const OfflineException();
  }

  /// Reactive offline classifier — true for a dropped/unreachable network
  /// surfacing as a `SocketException` or a connection-failure `ClientException`
  /// (covers the "on Wi-Fi but no real uplink" case the pre-flight can't see).
  static bool _isOfflineError(Object e) {
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

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.get<String>(StorageKeys.token);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': languageService.currentLanguage,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String>? _convertQueryParams(Map<String, dynamic>? params) {
    return params?.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('GET $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await client
          .get(uri, headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('GET $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('POST $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await client
          .post(
            uri,
            body: body == null ? null : jsonEncode(body),
            headers: await _getHeaders(),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('POST $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> getRaw(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('GET (raw) $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await client
          .get(uri, headers: await _getHeaders())
          .timeout(_timeout);
      return _handleRawResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('GET (raw) $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> postRaw(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('POST (raw) $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await client
          .post(
            uri,
            body: body == null ? null : jsonEncode(body),
            headers: await _getHeaders(),
          )
          .timeout(_timeout);
      return _handleRawResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('POST (raw) $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('PUT $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await client
          .put(uri, body: jsonEncode(body), headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('PUT $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('PATCH $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await client
          .patch(uri, body: jsonEncode(body), headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('PATCH $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('DELETE $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await client
          .delete(uri, headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('DELETE $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> postMultipart(
    String path, {
    required List<File> files,
    required String fieldName,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    if (files.isEmpty) {
      throw ArgumentError('postMultipart requires at least one file');
    }
    final uri = Uri.parse('${EndPoints.baseUrl}$path');
    AppLogger.info('POST (multipart) $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      // _getHeaders adds Content-Type: application/json. Multipart sets
      // its own Content-Type with boundary, so strip ours before
      // assigning — leaving both in place yields a malformed request.
      final headers = await _getHeaders();
      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      if (fields != null) request.fields.addAll(fields);

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        request.files.add(await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: 'file_$i${_extensionOf(file.path)}',
          contentType: MediaType('image', _mimeSubtype(file.path)),
        ));
      }

      final streamed =
          await client.send(request).timeout(timeout ?? _multipartTimeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      if (e is ArgumentError) rethrow;
      AppLogger.error('POST (multipart) $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot != -1 ? path.substring(dot) : '.jpg';
  }

  String _mimeSubtype(String path) {
    final ext = path.contains('.')
        ? path.substring(path.lastIndexOf('.') + 1).toLowerCase()
        : 'jpeg';
    return ext == 'jpg' ? 'jpeg' : ext;
  }

  dynamic _handleResponse(http.Response response) {
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
          // Status-envelope failure on a 2xx response. Surface the
          // optional `errorCode` so data-source classifiers can switch
          // on it instead of substring-matching the Arabic message.
          throw CodedServerException(
            message: responseBody['message'] ?? "Operation Failed",
            errorCode: responseBody is Map ? responseBody['errorCode'] as String? : null,
          );
        }
      } else {
        String errorMessage = _statusErrorMessage(response.statusCode);
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
                _statusErrorMessage(response.statusCode);
          }
        }
        AppLogger.error(
          '${response.statusCode} ${response.request?.url}: $errorMessage',
          tag: 'HTTP',
        );
        throw CodedServerException(
          message: errorMessage,
          errorCode: responseBody is Map ? responseBody['errorCode'] as String? : null,
        );
      }
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (_isOfflineError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error(
        '${response.statusCode} non-JSON body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
        tag: 'HTTP',
      );
      throw ServerException(message: _statusErrorMessage(response.statusCode));
    }
  }

  /// Same status-code handling as [_handleResponse] but does **not**
  /// enforce the `status == 1` envelope. Used by [getRaw] / [postRaw] for
  /// endpoints that return a raw List, a literal `null`, or a Map with
  /// a different success-flag shape (e.g. the subscriptions endpoints'
  /// `success: true/false`).
  ///
  /// Behaviour:
  /// * 2xx → returns the decoded body as-is, **except** when the body is
  ///   a Map with `success: false` (POST envelope used by `/subscribe`)
  ///   — in that case it throws `ServerException` with `message`.
  /// * non-2xx → throws `ServerException` with the parsed error message.
  dynamic _handleRawResponse(http.Response response) {
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
      var errorMessage = _statusErrorMessage(response.statusCode);
      String? errorCode;
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
      );
    }

    // ── 2xx success path (UNCHANGED) ──
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
      throw ServerException(message: _statusErrorMessage(response.statusCode));
    }

    if (body is Map<String, dynamic> && body['success'] == false) {
      throw CodedServerException(
        message: body['message'] as String? ?? 'Operation Failed',
        errorCode: body['errorCode'] as String?,
      );
    }
    // `status: 0` envelopes are NOT thrown here — data sources that
    // use `postRaw` inspect the body themselves and classify before
    // bubbling up (see `LikesRemoteDataSourceImpl._action` and the
    // matches data source). Throwing here would short-circuit that.
    return body;
  }

  String _errorMessage(Object e) {
    if (e is TimeoutException) return LocaleKeys.errors_timeout;
    return LocaleKeys.errors_generic;
  }

  String _statusErrorMessage(int statusCode) => switch (statusCode) {
    400 => LocaleKeys.errors_bad_request,
    401 => LocaleKeys.errors_unauthorized,
    403 => LocaleKeys.errors_forbidden,
    404 => LocaleKeys.errors_not_found,
    408 => LocaleKeys.errors_timeout,
    429 => LocaleKeys.errors_too_many_requests,
    500 || 502 || 503 => LocaleKeys.errors_server,
    _ => LocaleKeys.errors_generic,
  };
}
