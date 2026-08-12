import '../../../shared/data/json_parsers.dart';
import 'package:qeran/core/data/display_name.dart';
import '../../../../../core/utils/server_datetime.dart';
import '../../../users/domain/entities/matchmaker_card_answer.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_image.dart';
import '../../domain/entities/matchmaker_interest_like.dart';
import '../interest_parsers.dart';

/// Wire model for the matchmaker LikeRequestCardDto — read-only fields only
/// (actions[] + remainingSeconds + createdAt are ignored; the like DTO has no
/// age). Confirmed fields: profileId / name / profileImage / status (0-3) /
/// isLocked / answers. Aliases kept as a defensive fallback.
class MatchmakerInterestLikeModel {
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final MatchmakerInterestLikeStatus status;
  final bool isLocked;
  final int? age;
  final int? remainingSeconds;
  final DateTime? expiresAt;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestLikeModel({
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.status,
    required this.isLocked,
    required this.age,
    this.remainingSeconds,
    this.expiresAt,
    required this.answers,
  });

  factory MatchmakerInterestLikeModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerInterestLikeModel(
        otherUserId: parseString(
          json['profileId'] ?? json['otherUserId'] ?? json['userId'],
        ),
        name: parseDisplayName(json),
        image: parseInterestImage(json['profileImage'] ?? json['image']),
        status: matchmakerLikeStatusFromWire(json['status']),
        isLocked: parseBool(json['isLocked']),
        age: parseNullableInt(json['age']),
        remainingSeconds: parseNullableInt(json['remainingSeconds']),
        expiresAt: parseServerDateTime(json['expiresAt']),
        answers: parseInterestAnswers(json['answers']),
      );

  MatchmakerInterestLike toEntity() => MatchmakerInterestLike(
    otherUserId: otherUserId,
    name: name,
    image: image,
    status: status,
    isLocked: isLocked,
    age: age,
    remainingSeconds: remainingSeconds,
    expiresAt: expiresAt,
    answers: answers,
  );
}
