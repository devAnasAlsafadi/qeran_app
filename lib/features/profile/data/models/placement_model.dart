import '../../domain/entities/placement.dart';
import '../../domain/entities/placement_code.dart';
import '../json_parsers.dart';
import 'placement_item_model.dart';

class PlacementModel {
  final String placement;
  final int placementCode;
  final String placementName;
  final List<PlacementItemModel> items;

  /// The first dashboard key its items send (`items[].categoryKey`, TQ18,
  /// run 11), null when none is set.
  final String? categoryKey;

  /// An item sends `categoryKey` (null or not). Before Tariq's deploy none
  /// does, and the icon goes by [placementName].
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
    final keyed = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .where((item) => item.containsKey('categoryKey'))
            .toList(growable: false)
        : const <Map<String, dynamic>>[];
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
      categoryKey: keyed
          .map((item) => parseNullableString(item['categoryKey']))
          .firstWhere((key) => key != null && key.trim().isNotEmpty,
              orElse: () => null),
      hasCategoryKey: keyed.isNotEmpty,
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
