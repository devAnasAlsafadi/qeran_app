import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// The multipart POST behind `HttpConsumer.postMultipart`: [headers] are the
/// consumer's own minus `Content-Type` — multipart sets its own with the
/// boundary, and leaving both in place yields a malformed request.
Future<http.MultipartRequest> buildMultipartRequest(
  Uri uri, {
  required Map<String, String> headers,
  required List<File> files,
  required String fieldName,
  Map<String, String>? fields,
}) async {
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
  return request;
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
