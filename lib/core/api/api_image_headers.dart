import 'end_points.dart';

/// The headers to load the image at [url] with: our Bearer [token] only when
/// [url] is on our own API's origin — the scheme, host and port of
/// [EndPoints.baseUrl]. Anything else gets none: signed video URLs and their
/// posters (W5), another host's images, the dev mock's media. A relative
/// [url] gets none either; resolve it with [EndPoints.absoluteUrl] first.
Map<String, String>? imageHeadersFor(String url, {required String? token}) {
  if (token == null || token.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || !isApiOrigin(uri)) return null;
  return {'Authorization': 'Bearer $token'};
}

/// Whether [uri] is on our own API's origin. Compares the parsed parts, so a
/// look-alike (`…rtempurl.com.evil.example`, `…rtempurl.com@evil.example`)
/// or plain `http` is not ours.
bool isApiOrigin(Uri uri) {
  final api = Uri.parse(EndPoints.baseUrl);
  return uri.scheme == api.scheme &&
      uri.host == api.host &&
      uri.port == api.port;
}
