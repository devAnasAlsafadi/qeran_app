import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/matchmaker_card_answer.dart';
import 'matchmaker_interest_enums.dart';
import 'matchmaker_interest_image.dart';

/// One like row (outgoing or incoming) in the read-only matchmaker mirror — the
/// OTHER party plus the matchmaker's flagged answers. Actions and the live
/// countdown are intentionally dropped (view-only). When [isLocked] the backend
/// redacts the identity (the viewed user has no subscription); the UI shows a
/// neutral redaction, never a buy CTA.
class MatchmakerInterestLike extends Equatable {
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final MatchmakerInterestLikeStatus status;
  final bool isLocked;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestLike({
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.status,
    required this.isLocked,
    this.age,
    this.answers = const [],
  });

  @override
  List<Object?> get props =>
      [otherUserId, name, image, status, isLocked, age, answers];
}
