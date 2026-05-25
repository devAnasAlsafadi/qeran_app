import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/placement_value.dart';

/// Polymorphic parser for the server's `value` / `display` fields.
///
/// Wire shape is either `String` or `List<dynamic>`; in-memory shape is
/// the sealed [PlacementValue]. This is the single decision point for
/// resolving the polymorphism. Tests exercise each branch.
class PlacementValueModel {
  PlacementValueModel._();

  static PlacementValue fromJson(dynamic raw) {
    if (raw == null) return const PlacementSingle('');
    if (raw is String) return PlacementSingle(raw);
    if (raw is List) {
      return PlacementMulti(raw.map((e) => e.toString()).toList());
    }
    AppLogger.warning(
      'PlacementValue unexpected shape: ${raw.runtimeType}',
      tag: 'DISCOVERY',
    );
    return const PlacementSingle('');
  }
}
