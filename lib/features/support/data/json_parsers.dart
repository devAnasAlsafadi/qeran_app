/// Defensive JSON parsers for the support models. Mirrors the per-feature
/// copies (e.g. `features/legal/data/json_parsers.dart`) — each module keeps
/// its own so features stay decoupled. Tolerates int↔string drift so one
/// misaligned wire field never collapses a category row.
library;

int? parseNullableInt(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

int parseInt(Object? raw, {int fallback = 0}) =>
    parseNullableInt(raw) ?? fallback;

String? parseNullableString(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is num || raw is bool) return raw.toString();
  return null;
}

String parseString(Object? raw, {String fallback = ''}) =>
    parseNullableString(raw) ?? fallback;

/// Normalises any `Map` into `Map<String, dynamic>`. A naive
/// `is Map<String, dynamic>` guard silently drops `Map<dynamic, dynamic>`.
Map<String, dynamic>? parseNullableMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    try {
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Normalises a JSON array into `List<Map<String, dynamic>>`, dropping any
/// non-object entries. Used for the `data: [...]` categories payload.
List<Map<String, dynamic>> parseMapList(Object? raw) {
  if (raw is List) {
    return raw
        .map(parseNullableMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
  return const [];
}
