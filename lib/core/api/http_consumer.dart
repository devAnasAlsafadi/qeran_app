import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qeran/core/constants/storage_keys.dart';
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
    final token = await storage.get<String>(StorageKeys.token);
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

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse("${EndPoints.baseUrl}$path")
        .replace(queryParameters: _convertQueryParams(queryParameters));
    AppLogger.info('DELETE $uri', tag: 'HTTP');
    try {
      final response = await client
          .delete(uri, headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('DELETE $uri failed', error: e, tag: 'HTTP');
      throw ServerException(message: _errorMessage(e));
    }
  }

  dynamic _handleResponse(http.Response response) {
    AppLogger.debug('${response.statusCode} ${response.request?.url}', tag: 'HTTP');
    try {
      final dynamic responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['status'] == 1 || responseBody['status'] == true) {
          return responseBody;
        } else {
          throw ServerException(message: responseBody['message'] ?? "Operation Failed");
        }
      } else {
        String errorMessage = _statusErrorMessage(response.statusCode);
        if (responseBody is Map) {
          if (responseBody['errors'] != null && responseBody['errors'] is Map) {
            final Map<String, dynamic> errors = Map<String, dynamic>.from(responseBody['errors']);
            if (errors.isNotEmpty) {
              final firstList = errors.values.first;
              if (firstList is List && firstList.isNotEmpty) {
                errorMessage = firstList.first.toString();
              }
            }
          } else {
            errorMessage = responseBody['message'] as String?
                ?? responseBody['error'] as String?
                ?? _statusErrorMessage(response.statusCode);
          }
        }
        AppLogger.error('${response.statusCode} ${response.request?.url}: $errorMessage', tag: 'HTTP');
        throw ServerException(message: errorMessage);
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error(
        '${response.statusCode} non-JSON body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
        tag: 'HTTP',
      );
      throw ServerException(message: _statusErrorMessage(response.statusCode));
    }
  }

  String _errorMessage(Object e) {
    if (e is TimeoutException) return "Request timed out. Please try again.";
    return "Connection error: ${e.toString()}";
  }

  String _statusErrorMessage(int statusCode) => switch (statusCode) {
        400 => 'البيانات المدخلة غير صحيحة',
        401 => 'غير مصرح بالوصول',
        403 => 'ليس لديك صلاحية للوصول',
        404 => 'لم يتم العثور على المورد',
        408 => 'انتهت مهلة الطلب',
        429 => 'طلبات كثيرة، حاول لاحقاً',
        500 || 502 || 503 => 'خطأ في الخادم، حاول لاحقاً',
        _ => 'حدث خطأ، حاول مرة أخرى',
      };
}


