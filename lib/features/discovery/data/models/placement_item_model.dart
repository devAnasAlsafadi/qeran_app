import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_item_type.dart';
import '../../domain/entities/placement_value.dart';
import 'placement_value_model.dart';

class PlacementItemModel {
  final int questionId;
  final String question;
  final String typeRaw;
  final PlacementValue value;
  final PlacementValue display;

  const PlacementItemModel({
    required this.questionId,
    required this.question,
    required this.typeRaw,
    required this.value,
    required this.display,
  });

  factory PlacementItemModel.fromJson(Map<String, dynamic> json) {
    return PlacementItemModel(
      questionId: json['questionId'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      typeRaw: json['type'] as String? ?? '',
      value: PlacementValueModel.fromJson(json['value']),
      display: PlacementValueModel.fromJson(json['display']),
    );
  }

  PlacementItem toEntity() => PlacementItem(
        questionId: questionId,
        question: question,
        type: PlacementItemType.fromString(typeRaw),
        value: value,
        display: display,
      );
}
