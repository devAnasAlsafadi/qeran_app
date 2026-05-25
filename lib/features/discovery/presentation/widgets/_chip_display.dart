import 'package:flutter/widgets.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_item_type.dart';
import '../../domain/entities/placement_value.dart';

/// Pure renderer for a chip's display text. Joins multi-values with the
/// Arabic comma and appends a unit suffix for weight/height when the
/// caller supplies one. Independent of `BuildContext` so it is unit
/// testable without an `EasyLocalization` ancestor.
String chipDisplayPure(
  PlacementItem item, {
  String? unitKg,
  String? unitCm,
}) {
  final base = switch (item.display) {
    PlacementSingle(value: final v) => v,
    PlacementMulti(values: final vs) => vs.join('، '),
  };
  return switch (item.type) {
    PlacementItemType.weight when unitKg != null => '$base $unitKg',
    PlacementItemType.height when unitCm != null => '$base $unitCm',
    _ => base,
  };
}

/// Convenience wrapper that pulls the localized weight/height unit
/// suffix from the current locale only when the item type needs one,
/// and delegates to [chipDisplayPure]. Used by the chip widgets at
/// render time. Short-circuiting matters: chip widget tests don't
/// mount `EasyLocalization`, so we must not touch `.t(context)` for
/// types that don't need a suffix.
String chipDisplay(PlacementItem item, BuildContext context) {
  return switch (item.type) {
    PlacementItemType.weight => chipDisplayPure(
        item,
        unitKg: LocaleKeys.discovery_unit_kg.t(context),
      ),
    PlacementItemType.height => chipDisplayPure(
        item,
        unitCm: LocaleKeys.discovery_unit_cm.t(context),
      ),
    _ => chipDisplayPure(item),
  };
}
