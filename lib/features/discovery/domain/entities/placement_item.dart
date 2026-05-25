import 'package:equatable/equatable.dart';

import 'placement_item_type.dart';
import 'placement_value.dart';

class PlacementItem extends Equatable {
  /// Server's question identifier. Stable across response shapes.
  final int questionId;

  /// Localized question text (Arabic in our market).
  final String question;

  final PlacementItemType type;

  /// Canonical key for the answer (e.g. `"SaudiArabia"`, or
  /// `["Funny", "Ambitious"]` for multi-valued types).
  final PlacementValue value;

  /// Human-readable rendering of the answer (e.g. `"السعودية"`, or
  /// `["😄 مرح", "🎯 طموح"]`). Use this in the UI; never render [value].
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
