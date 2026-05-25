import 'package:equatable/equatable.dart';

import 'placement_code.dart';
import 'placement_item.dart';

class Placement extends Equatable {
  final PlacementCode code;

  /// Server-supplied section header (Arabic), e.g. `"نبذة عني"`.
  /// Some placement codes have a fixed name; `defaultGroup` uses this
  /// to distinguish multiple generic sections from each other.
  final String name;

  final List<PlacementItem> items;

  const Placement({
    required this.code,
    required this.name,
    required this.items,
  });

  @override
  List<Object?> get props => [code, name, items];
}
