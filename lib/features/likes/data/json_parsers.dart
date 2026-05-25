/// Defensive JSON parsers for the Matches / photo-exchange models.
///
/// Backend has been observed to send some fields as either int or
/// String depending on rollout (e.g. `status` arrives as the enum
/// string `"Pending"` or as the numeric `statusCode`). Direct
/// `as String?` casts crash the whole list parse when a single field
/// flips type; these helpers tolerate either shape so one drifted
/// field never blanks the entire Matches tab.
library;

/// Parses an integer from raw JSON. Accepts an `int`, any `num`
/// (truncated via `toInt`), or a numeric string. Returns `null` for
/// anything else, including `null` itself and non-numeric strings.
int? parseNullableInt(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

/// Parses an integer with a default fallback when the field is
/// missing or unparseable. Use only for ids the entity contract
/// requires.
int parseInt(Object? raw, {int fallback = 0}) =>
    parseNullableInt(raw) ?? fallback;

/// Parses a string from raw JSON. Accepts an actual `String`, or
/// stringifies an `int` / `num` / `bool` via `toString`. Returns
/// `null` for `null` and for collections / maps (which would
/// stringify to something useless like `"[Instance of ...]"`).
String? parseNullableString(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is num || raw is bool) return raw.toString();
  return null;
}

/// Parses a string with a default fallback. Use for fields the entity
/// contract requires non-null (e.g. `otherUserName`).
String parseString(Object? raw, {String fallback = ''}) =>
    parseNullableString(raw) ?? fallback;

/// Parses a boolean tolerantly. Accepts an actual `bool`, `1`/`0`
/// integers, or the literal strings `"true"`/`"false"` (case-
/// insensitive). Returns [fallback] otherwise.
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

/// Parses an ISO-8601 timestamp. Returns `null` when the field is
/// missing, empty, or unparseable.
DateTime? parseNullableDateTime(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
