import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/matchmaker_card_answer.dart';
import 'matchmaker_interest_image.dart';

/// One archived (closed / cancelled) match in the read-only mirror — simpler
/// than an active match: the OTHER party + a server [outcome] label. ⚠️ The
/// ArchiveItemDto shape is the least-confirmed of the four payloads; fields are
/// parsed defensively (see the model).
class MatchmakerInterestArchiveItem extends Equatable {
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final String outcome;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestArchiveItem({
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.outcome,
    this.age,
    this.answers = const [],
  });

  @override
  List<Object?> get props => [otherUserId, name, image, outcome, age, answers];
}
