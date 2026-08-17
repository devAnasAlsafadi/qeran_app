/// Defensive JSON parsers for the discovery models. Mirrors the per-feature
/// copies in `features/notifications/data/json_parsers.dart` and
/// `features/matchmaker/shared/data/json_parsers.dart` — each module keeps its
/// own copy so features stay decoupled. Trimmed to what discovery actually
/// needs. The functions tolerate int↔string and bool↔int/string drift so one
/// misaligned wire field never collapses a whole filter sheet.
library;

int? parseNullableInt(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

/// Nullable bool for fields the server may omit entirely — absent or
/// unparseable → `null`, so the caller can tell "the dashboard hasn't set
/// this" from an explicit `false`. Both distinctions matter for the filter
/// question flags: null means "fall back to the client's inference".
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
