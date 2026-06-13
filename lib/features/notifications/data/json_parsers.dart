/// Defensive JSON parsers for the user-app notifications models. Mirrors the
/// per-feature copies in `features/likes/data/json_parsers.dart` and
/// `features/matchmaker/shared/data/json_parsers.dart` — each module keeps its
/// own copy so features stay decoupled. The functions tolerate int↔string drift
/// (the backend sends numbers-as-strings in some payloads — notably the FCM
/// `data` map and a few DTOs) so one misaligned wire field never collapses the
/// whole inbox.
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

DateTime? parseNullableDateTime(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Normalises any `Map` into `Map<String, dynamic>`. JSON / FCM paths sometimes
/// hand us `Map<dynamic, dynamic>`; a naive `is Map<String, dynamic>` guard
/// silently drops those.
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
/// non-object entries. Used for the bare-array `data: [...]` payload shape.
List<Map<String, dynamic>> parseMapList(Object? raw) {
  if (raw is List) {
    return raw
        .map(parseNullableMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
  return const [];
}
