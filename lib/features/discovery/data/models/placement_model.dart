import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/placement.dart';
import '../../domain/entities/placement_code.dart';
import 'placement_item_model.dart';

class PlacementModel {
  final PlacementCode code;
  final String name;
  final List<PlacementItemModel> items;

  const PlacementModel({
    required this.code,
    required this.name,
    required this.items,
  });

  /// Returns `null` for placements whose `placementCode` the client does
  /// not recognize. Caller filters with `whereType<PlacementModel>()`.
  static PlacementModel? tryParse(Map<String, dynamic> json) {
    final rawCode = json['placementCode'] as int? ?? -1;
    final code = PlacementCode.fromInt(rawCode);
    if (code == null) {
      AppLogger.warning(
        'Unknown placementCode dropped: $rawCode',
        tag: 'DISCOVERY',
      );
      return null;
    }
    return PlacementModel(
      code: code,
      name: json['placementName'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlacementItemModel.fromJson)
          .toList(),
    );
  }

  Placement toEntity() => Placement(
        code: code,
        name: name,
        items: items.map((i) => i.toEntity()).toList(),
      );
}
