import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'json_parsers.dart';

/// Shared helpers for the two matchmaker response quirks.
///
/// Kept out of `json_parsers.dart` (pure value parsers) because these
/// reach into the API envelope and may throw a [CodedServerException].

/// Reaches the payload inside a DOUBLE-wrapped matchmaker response.
///
/// Some endpoints (profile detail, editable answers) wrap their payload
/// twice: the consumer's `get` already handled the OUTER envelope, so
/// [outerData] is `response['data']` — which is ITSELF a
/// `{status, data, message, errorCode}` envelope whose `data` holds the
/// real object. This unwraps that inner envelope.
///
/// Tolerant of a future flatten: a map with no `status` key is assumed to
/// already be the payload and returned as-is. An inner `status != 1` is
/// surfaced as a [CodedServerException] so the repository maps it to a
/// Failure like any other.
Map<String, dynamic>? unwrapInnerEnvelope(Object? outerData) {
  if (outerData is! Map<String, dynamic>) return null;
  // No `status` → already the payload (flattened / future shape).
  if (!outerData.containsKey('status')) return outerData;
  // It's the inner envelope — honour its status, then unwrap.
  final status = outerData['status'];
  if (status != 1 && status != true) {
    throw _codedFrom(outerData);
  }
  final inner = outerData['data'];
  return inner is Map<String, dynamic> ? inner : null;
}

/// Classifies a matchmaker MUTATION response read through `postRaw`.
///
/// These endpoints carry the human-readable result in `data` (a String)
/// with an empty `message`. `status == 1` is success regardless — returns
/// the `data`/`message` text (possibly empty). On `status != 1`, throws a
/// [CodedServerException] carrying whichever of `data` / `message` is
/// non-empty, falling back to a generic localized error.
String mutationResultText(Object? response) {
  if (response is! Map<String, dynamic>) {
    throw ServerException(message: LocaleKeys.errors_generic);
  }
  final status = response['status'];
  if (status == 1 || status == true) {
    return _firstNonEmpty([
          parseNullableString(response['data']),
          parseNullableString(response['message']),
        ]) ??
        '';
  }
  throw _codedFrom(response);
}

CodedServerException _codedFrom(Map<String, dynamic> envelope) {
  final text = _firstNonEmpty([
    parseNullableString(envelope['data']),
    parseNullableString(envelope['message']),
  ]);
  return CodedServerException(
    message: (text == null || text.isEmpty) ? LocaleKeys.errors_generic : text,
    errorCode: parseNullableString(envelope['errorCode']),
  );
}

String? _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}
