import 'package:equatable/equatable.dart';

import '../../../../../core/utils/server_clock.dart';
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
  final int? remainingSeconds;
  final DateTime? expiresAt;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestLike({
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.status,
    required this.isLocked,
    this.age,
    this.remainingSeconds,
    this.expiresAt,
    this.answers = const [],
  });

  /// Still genuinely open — see `LikeRequestCard.isAwaitingResponse`; the
  /// matchmaker mirrors the same rows off the same endpoints, so the rule has
  /// to match or the two apps disagree about one request.
  bool get isAwaitingResponse =>
      status == MatchmakerInterestLikeStatus.pending &&
      !hasServerExpired(expiresAt);

  @override
  List<Object?> get props => [
    otherUserId,
    name,
    image,
    status,
    isLocked,
    age,
    remainingSeconds,
    expiresAt,
    answers,
  ];
}
