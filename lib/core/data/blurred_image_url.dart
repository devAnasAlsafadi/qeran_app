import 'package:qeran/core/api/end_points.dart';

/// Resolves a server-rendered blurred image URL, or null when the payload has
/// none.
///
/// These are a genuinely different resource from the original: the server has
/// already destroyed the detail, so the bytes are safe to fetch, cache and
/// display at any point — including while the one-time photo-view policy is
/// refusing to fetch the ORIGINAL. That distinction is the whole reason a
/// locked photo can now show a real silhouette instead of a lock glyph.
///
/// Null (rather than an empty string) so call sites can branch on presence and
/// fall back to the client-side blur.
String? parseBlurredUrl(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return EndPoints.absoluteUrl(text);
}
