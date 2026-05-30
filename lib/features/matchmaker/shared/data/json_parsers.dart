/// Defensive JSON parsers for matchmaker models. Same approach as
/// `features/chat/data/json_parsers.dart` and
/// `features/likes/data/json_parsers.dart` — each feature module keeps
/// its own copy so modules stay decoupled. The functions tolerate
/// int↔string drift (the backend sends numbers-as-strings in some
/// payloads, e.g. FCM and a few DTOs) so a single misaligned wire field
/// never collapses a whole screen.
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

double? parseNullableDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

double parseDouble(Object? raw, {double fallback = 0.0}) =>
    parseNullableDouble(raw) ?? fallback;

String? parseNullableString(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is num || raw is bool) return raw.toString();
  return null;
}

String parseString(Object? raw, {String fallback = ''}) =>
    parseNullableString(raw) ?? fallback;

bool parseBool(Object? raw, {bool fallback = false}) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final s = raw.toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  return fallback;
}

/// Nullable bool for fields a list may omit entirely (e.g. pending rows
/// carry `hasProfileImage`, the approved lists don't). Absent / unparseable
/// → `null`, so the caller can tell "missing" from an explicit `false`.
bool? parseNullableBool(Object? raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final s = raw.toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  return null;
}

DateTime? parseNullableDateTime(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Normalises any `Map` into `Map<String, dynamic>`. JSON / SignalR
/// paths sometimes hand us `Map<dynamic, dynamic>`; a naive
/// `raw is Map<String, dynamic>` guard silently drops those. Use this
/// for nested object fields so one shape mismatch never nulls a
/// structured field.
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

/// Normalises a JSON array into `List<Map<String, dynamic>>`, dropping
/// any non-object entries. Used for `data: [...]` list payloads.
List<Map<String, dynamic>> parseMapList(Object? raw) {
  if (raw is List) {
    return raw
        .map(parseNullableMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
  return const [];
}
