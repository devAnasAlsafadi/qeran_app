import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/matchmaker_card_answer.dart';
import 'matchmaker_interest_enums.dart';
import 'matchmaker_interest_image.dart';

/// One archived (closed) item in the read-only mirror — a closed like or
/// photo-exchange ([type]) for the OTHER party. [status] is backend display
/// text (shown verbatim); [reason] drives the status-chip colour and a fallback
/// label. Archived items are historical — never redacted (no `isLocked`) and
/// carry no age.
class MatchmakerInterestArchiveItem extends Equatable {
  final MatchmakerArchiveType type;
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final String status;
  final MatchmakerArchiveReason reason;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestArchiveItem({
    required this.type,
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.status,
    required this.reason,
    this.answers = const [],
  });

  @override
  List<Object?> get props =>
      [type, otherUserId, name, image, status, reason, answers];
}
