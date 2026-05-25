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

  const Placement({
    required this.code,
    required this.name,
    required this.items,
  });

  @override
  List<Object?> get props => [code, name, items];
}
