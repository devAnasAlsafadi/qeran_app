import 'dart:io';

abstract class ApiConsumer {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters});

  /// Variant of [get] that **does not** enforce the `status == 1`
  /// envelope. Use this for endpoints that return a raw array, a raw
  /// `null`, or an unwrapped object (e.g. the subscriptions endpoints).
  /// Non-2xx responses still throw `ServerException` with the parsed
  /// message.
  Future<dynamic> getRaw(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  });

  /// Variant of [post] that **does not** enforce the `status == 1`
  /// envelope. Accepts `{success, message, data}`-shaped responses:
  /// throws `ServerException` when `success == false`, otherwise
  /// returns the decoded body verbatim.
  Future<dynamic> postRaw(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  });
  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  });
  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParameters});

  /// Uploads `files` as a multipart POST under `fieldName`. Auth + language
  /// headers come from the consumer's own storage/language service; the
  /// `Content-Type` header is set automatically by the multipart request
  /// (callers must not override it). Optional `fields` carry extra
  /// non-file form data. `timeout` overrides the consumer's default
  /// upload timeout when provided.
  Future<dynamic> postMultipart(
    String path, {
    required List<File> files,
    required String fieldName,
    Map<String, String>? fields,
    Duration? timeout,
  });
}
