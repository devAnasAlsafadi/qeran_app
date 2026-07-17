/// Defensive JSON parsers for profile models. Same approach as the
/// chat / likes feature parsers — kept feature-local so module
/// coupling stays clean. Tolerates int↔string drift so one misaligned
/// wire field never crashes the whole profile screen.
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

DateTime? parseNullableDateTime(Object? raw) => parseServerDateTime(raw);
