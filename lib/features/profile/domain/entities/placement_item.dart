import 'package:equatable/equatable.dart';

import 'placement_item_type.dart';
import 'placement_value.dart';

class PlacementItem extends Equatable {
  /// Stable server question identifier.
  final int questionId;

  /// Localised question text.
  final String question;

  final PlacementItemType type;

  /// Canonical key for the answer.
  final PlacementValue value;

  /// Human-readable rendering of the answer — always render this.
  final PlacementValue display;

  const PlacementItem({
    required this.questionId,
    required this.question,
    required this.type,
    required this.value,
    required this.display,
  });

  @override
  List<Object?> get props => [questionId, question, type, value, display];
}
