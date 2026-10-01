/// Defensive JSON parsers for the Community models. Mirrors the per-feature
/// copies (e.g. `features/chat/data/json_parsers.dart`) — each module keeps
/// its own so features stay decoupled. Tolerates int↔string drift so one
/// misaligned wire field never collapses a post or a whole page.
library;

import 'package:qeran/core/utils/server_datetime.dart';

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

DateTime? parseNullableDateTime(Object? raw) => parseServerDateTime(raw);

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

/// A JSON array as `List<Map<String, dynamic>>`, non-object entries dropped.
List<Map<String, dynamic>> parseMapList(Object? raw) {
  if (raw is List) {
    return raw
        .map(parseNullableMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
  return const [];
}

/// A JSON array of strings, trimmed and lower-cased, blanks dropped — for the
/// config's file-type lists (`["jpg", "png"]`).
List<String> parseLowerStringList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .map(parseNullableString)
      .whereType<String>()
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}
