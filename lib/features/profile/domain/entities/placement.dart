import 'package:equatable/equatable.dart';

import 'placement_code.dart';
import 'placement_item.dart';

class Placement extends Equatable {
  final PlacementCode code;

  /// Server-supplied section header (Arabic in our market). Some codes
  /// use a fixed name; [PlacementCode.defaultGroup] uses this to
  /// distinguish multiple generic sections.
  final String name;

  final List<PlacementItem> items;

  /// The category's English key, set in the dashboard (`religion`,
  /// `marriage`, …; `other` always exists). Null when the dashboard hasn't set
  /// one. Picks the section's icon.
  final String? categoryKey;

  /// Whether the payload sends `categoryKey` at all, set or null. False until
  /// Tariq's deploy, and the icon then goes by the section's name; this flag
  /// goes with that fallback (`14`, TQ18).
  final bool hasCategoryKey;

  const Placement({
    required this.code,
    required this.name,
    required this.items,
    this.categoryKey,
    this.hasCategoryKey = false,
  });

  @override
  List<Object?> get props => [code, name, items, categoryKey, hasCategoryKey];
}
