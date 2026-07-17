/// Parsing for backend timestamps.
///
/// The backend sends UTC instants **without** a timezone marker (proven: the
/// `/subscriptions/current` value matched RevenueCat's `Z`-suffixed value to the
/// second). Dart's `DateTime.parse` treats a marker-less string as **local**, so
/// a raw parse lands the instant off by the device's UTC offset — which flipped
/// active subscriptions to "expired". This helper interprets a marker-less
/// string as UTC, while leaving already-qualified strings (`Z` or a numeric
/// offset) untouched — so it stays correct both before and after the backend
/// starts sending proper ISO-8601 UTC.
library;

/// Parses a backend timestamp into a **local-zoned** [DateTime] of the correct
/// instant (local wall-clock, so callers can format it for display directly),
/// or `null` when [raw] is absent, empty, or unparseable.
///
/// A marker-less string is interpreted as UTC (a `Z` is appended); a string
/// that already carries `Z`/`z` or a `±HH:MM` / `±HHMM` offset is parsed as-is
/// — never double-qualified. Comparisons remain correct regardless of the
/// returned value's `isUtc` flag, since Dart's `isBefore` / `difference`
/// operate on absolute instants.
DateTime? parseServerDateTime(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  var s = raw.trim();
  final hasTz = s.endsWith('Z') ||
      s.endsWith('z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
  if (!hasTz) s = '${s}Z';
  return DateTime.tryParse(s)?.toLocal();
}
