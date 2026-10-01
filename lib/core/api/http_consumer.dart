import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:qeran/core/constants/storage_keys.dart';
import '../app_logger.dart';
import '../errors/exceptions.dart';
import '../services/connectivity_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import 'api_consumer.dart';
import 'end_points.dart';
import 'http_errors.dart';
import 'http_multipart.dart';
import 'http_response_handler.dart';

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
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _request('GET', path, queryParameters,
          (uri, headers) => client.get(uri, headers: headers));

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request('POST', path, queryParameters, (uri, headers) => client.post(
            uri,
            body: body == null ? null : jsonEncode(body),
            headers: headers,
          ));

  @override
  Future<dynamic> getRaw(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _request('GET (raw)', path, queryParameters,
          (uri, headers) => client.get(uri, headers: headers),
          raw: true);

  @override
  Future<dynamic> postRaw(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request('POST (raw)', path, queryParameters,
          (uri, headers) => client.post(
                uri,
                body: body == null ? null : jsonEncode(body),
                headers: headers,
              ),
          raw: true);

  @override
  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request('PUT', path, queryParameters,
          (uri, headers) => client.put(uri, body: jsonEncode(body), headers: headers));

  @override
  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request('PATCH', path, queryParameters,
          (uri, headers) => client.patch(uri, body: jsonEncode(body), headers: headers));

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParameters}) =>
      _request('DELETE', path, queryParameters,
          (uri, headers) => client.delete(uri, headers: headers));

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
      final request = await buildMultipartRequest(
        uri,
        headers: await _getHeaders(),
        files: files,
        fieldName: fieldName,
        fields: fields,
      );
      final streamed =
          await client.send(request).timeout(timeout ?? _multipartTimeout);
      final response = await http.Response.fromStream(streamed);
      return handleEnvelopedResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (isOfflineTransportError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      if (e is ArgumentError) rethrow;
      AppLogger.error('POST (multipart) $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: transportErrorMessage(e));
    }
  }

  /// One request: the offline pre-flight, the shared headers, the 30 s
  /// timeout, then the enveloped (or [raw]) response handling. Anything that
  /// isn't already offline or a server error becomes a generic or timeout
  /// `ServerException`.
  Future<dynamic> _request(
    String label,
    String path,
    Map<String, dynamic>? queryParameters,
    Future<http.Response> Function(Uri uri, Map<String, String> headers) send, {
    bool raw = false,
  }) async {
    final uri = Uri.parse(
      "${EndPoints.baseUrl}$path",
    ).replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('$label $uri', tag: 'HTTP');
    try {
      await _ensureOnline();
      final response = await send(uri, await _getHeaders()).timeout(_timeout);
      return raw ? handleRawResponse(response) : handleEnvelopedResponse(response);
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (isOfflineTransportError(e)) throw const OfflineException();
      if (e is ServerException) rethrow;
      AppLogger.error('$label $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: transportErrorMessage(e));
    }
  }
}
