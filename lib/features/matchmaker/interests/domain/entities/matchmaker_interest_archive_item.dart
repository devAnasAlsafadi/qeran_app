import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/matchmaker_card_answer.dart';
import 'matchmaker_interest_enums.dart';
import 'matchmaker_interest_image.dart';

/// One archived (closed) item in the read-only mirror — a closed like or
/// photo-exchange ([type]) for the OTHER party. [statusName] is the backend's
/// pre-translated, locale-aware status label; raw [status] is kept only as a
/// fallback for old records, and [reason] drives the status-chip colour (and a
/// final fallback label). Archived items are historical — never redacted (no
/// `isLocked`) and carry no age.
class MatchmakerInterestArchiveItem extends Equatable {
  final MatchmakerArchiveType type;
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final String status;
  final String statusNameAr;
  final String statusNameEn;
  final MatchmakerArchiveReason reason;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestArchiveItem({
    required this.type,
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.status,
    this.statusNameAr = '',
    this.statusNameEn = '',
    required this.reason,
    this.answers = const [],
  });

  /// Backend status label, locale-aware (Arabic default; English when in
  /// English and provided). Empty when the backend sent neither (old records).
  String statusName({required bool isArabic}) =>
      isArabic ? statusNameAr : (statusNameEn.isNotEmpty ? statusNameEn : statusNameAr);

  @override
  List<Object?> get props => [
        type,
        otherUserId,
        name,
        image,
        status,
        statusNameAr,
        statusNameEn,
        reason,
        answers,
      ];
}
