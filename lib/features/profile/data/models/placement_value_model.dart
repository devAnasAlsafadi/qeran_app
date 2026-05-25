import '../../domain/entities/placement_value.dart';

/// Normalises the polymorphic `value` / `display` fields to a
/// [PlacementValue]. Backend ships String for single answers and
/// `List<String>` for multi answers.
PlacementValue parsePlacementValue(Object? raw) {
  if (raw is String) return PlacementSingle(raw);
  if (raw is num || raw is bool) return PlacementSingle(raw.toString());
  if (raw is List) {
    final out = <String>[];
    for (final v in raw) {
      if (v is String) {
        if (v.isNotEmpty) out.add(v);
      } else if (v != null) {
        final s = v.toString();
        if (s.isNotEmpty) out.add(s);
      }
    }
    return PlacementMulti(out);
  }
  return const PlacementSingle('');
}
