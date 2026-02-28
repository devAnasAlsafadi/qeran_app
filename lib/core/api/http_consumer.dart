import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/exceptions.dart';
import 'api_consumer.dart';
import 'end_points.dart';

  class HttpConsumer extends ApiConsumer {
    final http.Client client;
    final SharedPreferences sharedPreferences;

    HttpConsumer({required this.client, required this.sharedPreferences});

    Map<String, String> _getHeaders() {
      final token = sharedPreferences.getString("CACHED_TOKEN");

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
    Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? queryParameters}) async {
      final uri = Uri.parse("${EndPoints.baseUrl}$path").replace(queryParameters: _convertQueryParams(queryParameters));

      try {
        final response = await client.patch(
          uri,
          body: jsonEncode(body),
          headers: _getHeaders(),
        );

        return _handleResponse(response);
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(message: "Connection Error: ${e.toString()}");
      }
    }
    
    @override
    Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
      final uri = Uri.parse("${EndPoints.baseUrl}$path").replace(queryParameters: _convertQueryParams(queryParameters));

      try {
        final response = await client.get(uri, headers: _getHeaders());
        return _handleResponse(response);
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(message: "Connection Error: ${e.toString()}");
      }
    }

    @override
    Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? queryParameters}) async {
      final uri = Uri.parse("${EndPoints.baseUrl}$path").replace(queryParameters: _convertQueryParams(queryParameters));

      try {
        final response = await client.post(
          uri,
          body: jsonEncode(body),
            headers: _getHeaders(),
        );
        return _handleResponse(response);
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(message: "Connection Error: ${e.toString()}");
      }
    }

    dynamic _handleResponse(http.Response response) {
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
            }else{
              errorMessage = responseBody['message'] ?? "Error: ${response.statusCode}";
            }
          }
          throw ServerException(message: errorMessage);
        }
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(message: "Error interpreting server response");
      }
    }
  }