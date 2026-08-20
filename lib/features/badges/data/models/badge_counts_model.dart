import '../../domain/entities/badge_counts.dart';

/// Parses `GET /api/badges`.
///
/// Tolerant by contract, not by habit. The server may add keys we have never
/// heard of, may omit every zero, and — depending on the route — may hand the
/// dict back bare or wrapped in the usual `{status, data}` envelope. None of
/// those may throw: a badge is decoration, and a parser that crashes over one
/// would take a whole shell's navigation down with it.
class BadgeCountsModel {
  const BadgeCountsModel._();

  /// Accepts the bare dict and the enveloped form alike. Anything that is not
  /// a map of readable numbers yields empty counts, which render as no badges
  /// at all — the honest reading of "we could not learn anything".
  static BadgeCounts fromJson(Object? raw) {
    final body = _unwrap(raw);
    if (body == null) return const BadgeCounts.empty();

    final counts = <String, int>{};
    body.forEach((key, value) {
      if (key is! String || key.isEmpty) return;
      final count = _asCount(value);
      // Zero and absent mean the same thing to every reader, so there is
      // nothing to gain by storing zeros.
      if (count > 0) counts[key] = count;
    });
    return BadgeCounts(counts);
  }

  /// Returns the dict itself when the body is bare, or `data` when the body is
  /// the standard envelope. `data` is only preferred when it is itself a map —
  /// a bare dict that happens to carry a `data` key of its own is left alone.
  static Map<Object?, Object?>? _unwrap(Object? raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is Map) return data;
    return raw;
  }

  /// Counts arrive as ints, but a JSON number can decode as a double and some
  /// endpoints in this backend stringify numerics. Anything unreadable, or
  /// negative, is nothing to show.
  static int _asCount(Object? value) {
    final parsed = switch (value) {
      int n => n,
      double d => d.isFinite ? d.toInt() : 0,
      String s => int.tryParse(s.trim()) ?? 0,
      _ => 0,
    };
    return parsed > 0 ? parsed : 0;
  }
}
