import '../../domain/entities/placement.dart';
import '../../domain/entities/placement_code.dart';
import '../json_parsers.dart';
import 'placement_item_model.dart';

class PlacementModel {
  final String placement;
  final int placementCode;
  final String placementName;
  final List<PlacementItemModel> items;

  const PlacementModel({
    required this.placement,
    required this.placementCode,
    required this.placementName,
    required this.items,
  });

  factory PlacementModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PlacementItemModel.fromJson)
            .toList(growable: false)
        : const <PlacementItemModel>[];
    return PlacementModel(
      placement: parseString(json['placement']),
      placementCode: parseInt(json['placementCode']),
      placementName: parseString(json['placementName']),
      items: items,
    );
  }

  Placement toEntity() => Placement(
        code: PlacementCode.fromInt(placementCode),
        name: placementName,
        items: items.map((i) => i.toEntity()).toList(growable: false),
      );
}
