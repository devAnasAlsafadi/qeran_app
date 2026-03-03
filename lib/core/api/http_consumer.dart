import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qeran/core/constants/app_constants.dart';
import '../app_logger.dart';
import '../errors/exceptions.dart';
import '../services/storage_service.dart';
import 'api_consumer.dart';
import 'end_points.dart';

class HttpConsumer extends ApiConsumer {
  final http.Client client;
  final StorageService storage;

  static const Duration _timeout = Duration(seconds: 30);

  HttpConsumer({required this.client, required this.storage});

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.get<String>(AppConstants.cachedToken);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String>? _convertQueryParams(Map<String, dynamic>? params) {
    return params?.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse("${EndPoints.baseUrl}$path")
        .replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('GET $uri', tag: 'HTTP');
    try {
      final response = await client.get(uri, headers: await _getHeaders()).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('GET $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse("${EndPoints.baseUrl}$path")
        .replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('POST $uri', tag: 'HTTP');
    try {
      final response = await client
          .post(uri, body: jsonEncode(body), headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('POST $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  @override
  Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse("${EndPoints.baseUrl}$path")
        .replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('PATCH $uri', tag: 'HTTP');
    try {
      final response = await client
          .patch(uri, body: jsonEncode(body), headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('PATCH $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  dynamic _handleResponse(http.Response response) {
    AppLogger.debug('${response.statusCode} ${response.request?.url}', tag: 'HTTP');
    try {
      final dynamic responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['status'] == true) {
          return responseBody;
        } else {
          throw ServerException(message: responseBody['message'] ?? "Operation Failed");
        }
      } else {
        String errorMessage = "Something went wrong";
        if (responseBody is Map) {
          if (response.statusCode == 422 && responseBody['errors'] != null) {
            final Map<String, dynamic> errors = responseBody['errors'];
            errorMessage = errors.values.first[0].toString();
          } else {
            errorMessage = responseBody['message'] ?? "Error: ${response.statusCode}";
          }
        }
        AppLogger.error('${response.statusCode} ${response.request?.url}: $errorMessage', tag: 'HTTP');
        throw ServerException(message: errorMessage);
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: "Error interpreting server response");
    }
  }

  String _errorMessage(Object e) {
    if (e is TimeoutException) return "Request timed out. Please try again.";
    return "Connection error: ${e.toString()}";
  }
}
