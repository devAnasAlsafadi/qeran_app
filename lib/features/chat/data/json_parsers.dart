/// Defensive JSON parsers for chat models. Same approach as
/// `features/likes/data/json_parsers.dart` (which is why we don't
/// import that one — chat must stay decoupled from the likes
/// feature module). The functions tolerate int↔string drift so a
/// single misaligned wire field never crashes the entire chat
/// thread.
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

DateTime? parseNullableDateTime(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Normalises any `Map` into `Map<String, dynamic>`. SignalR (and some
/// JSON paths) hand us `Map<dynamic, dynamic>` for nested objects; a
/// naive `raw is Map<String, dynamic>` guard silently drops them. Use
/// this for any nested object field so a single payload shape mismatch
/// never collapses a structured field to `null`.
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
