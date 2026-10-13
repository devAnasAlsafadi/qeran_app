import '../../domain/entities/placement.dart';
import '../../domain/entities/placement_code.dart';
import '../json_parsers.dart';
import 'placement_item_model.dart';

class PlacementModel {
  final String placement;
  final int placementCode;
  final String placementName;
  final List<PlacementItemModel> items;

  /// The category's dashboard key (`religion`, …), null when unset.
  final String? categoryKey;

  /// The payload sends `categoryKey` (null or not). Before Tariq's deploy it
  /// doesn't, and the icon goes by [placementName] (`14`, TQ18).
  final bool hasCategoryKey;

  const PlacementModel({
    required this.placement,
    required this.placementCode,
    required this.placementName,
    required this.items,
    this.categoryKey,
    this.hasCategoryKey = false,
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
      categoryKey: parseNullableString(json['categoryKey']),
      hasCategoryKey: json.containsKey('categoryKey'),
    );
  }

  Placement toEntity() => Placement(
        code: PlacementCode.fromInt(placementCode),
        name: placementName,
        items: items.map((i) => i.toEntity()).toList(growable: false),
        categoryKey: categoryKey,
        hasCategoryKey: hasCategoryKey,
      );
}
