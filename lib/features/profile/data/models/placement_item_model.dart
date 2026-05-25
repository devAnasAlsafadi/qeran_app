import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_item_type.dart';
import '../../domain/entities/placement_value.dart';
import '../json_parsers.dart';
import 'placement_value_model.dart';

class PlacementItemModel {
  final int questionId;
  final String question;
  final String type;
  final PlacementValue value;
  final PlacementValue display;

  const PlacementItemModel({
    required this.questionId,
    required this.question,
    required this.type,
    required this.value,
    required this.display,
  });

  factory PlacementItemModel.fromJson(Map<String, dynamic> json) {
    return PlacementItemModel(
      questionId: parseInt(json['questionId']),
      question: parseString(json['question']),
      type: parseString(json['type']),
      value: parsePlacementValue(json['value']),
      display: parsePlacementValue(json['display']),
    );
  }

  PlacementItem toEntity() => PlacementItem(
        questionId: questionId,
        question: question,
        type: PlacementItemType.fromString(type),
        value: value,
        display: display,
      );
}
