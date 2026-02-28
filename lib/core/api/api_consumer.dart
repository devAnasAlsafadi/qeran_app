abstract class ApiConsumer {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters});
  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? queryParameters});
  Future<dynamic> patch(
      String path, {
        Object? body,
        Map<String, dynamic>? queryParameters,
      });
}