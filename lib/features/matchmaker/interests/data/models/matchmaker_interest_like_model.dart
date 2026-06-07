import '../../../shared/data/json_parsers.dart';
import '../../../users/domain/entities/matchmaker_card_answer.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_image.dart';
import '../../domain/entities/matchmaker_interest_like.dart';
import '../interest_parsers.dart';

/// Wire model for the matchmaker LikeRequestCardDto — read-only fields only
/// (actions[] + remainingSeconds are ignored). ⚠️ Field names to confirm:
/// otherUserId / name / profileImage / status / isLocked / age / answers
/// (parsed across likely aliases).
class MatchmakerInterestLikeModel {
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final MatchmakerInterestLikeStatus status;
  final bool isLocked;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestLikeModel({
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.status,
    required this.isLocked,
    required this.age,
    required this.answers,
  });

  factory MatchmakerInterestLikeModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerInterestLikeModel(
        otherUserId: parseString(
          json['otherUserId'] ?? json['profileId'] ?? json['userId'],
        ),
        name: parseString(json['name'] ?? json['fullName']),
        image: parseInterestImage(json['profileImage'] ?? json['image']),
        status: matchmakerLikeStatusFromWire(json['status']),
        isLocked: parseBool(json['isLocked']),
        age: parseNullableInt(json['age']),
        answers: parseInterestAnswers(json['answers']),
      );

  MatchmakerInterestLike toEntity() => MatchmakerInterestLike(
        otherUserId: otherUserId,
        name: name,
        image: image,
        status: status,
        isLocked: isLocked,
        age: age,
        answers: answers,
      );
}
