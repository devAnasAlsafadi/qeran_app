import '../../../shared/data/json_parsers.dart';
import '../../../users/domain/entities/matchmaker_card_answer.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_image.dart';
import '../../domain/entities/matchmaker_interest_match.dart';
import '../interest_parsers.dart';

/// Wire model for the matchmaker MatchCardDto — read-only fields only
/// (pendingPhotoExchange / formalRequest / conversationId ignored). ⚠️ Field
/// names to confirm: otherUserId / otherUserName|name / images / stage /
/// isLocked / age / answers (parsed across likely aliases).
class MatchmakerInterestMatchModel {
  final String otherUserId;
  final String name;
  final List<MatchmakerInterestImage> images;
  final MatchmakerInterestMatchStage stage;
  final bool isLocked;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestMatchModel({
    required this.otherUserId,
    required this.name,
    required this.images,
    required this.stage,
    required this.isLocked,
    required this.age,
    required this.answers,
  });

  factory MatchmakerInterestMatchModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerInterestMatchModel(
        otherUserId: parseString(json['otherUserId'] ?? json['userId']),
        name: parseString(json['otherUserName'] ?? json['name']),
        images: parseInterestImages(json['images']),
        stage: matchmakerMatchStageFromWire(json['stage']),
        isLocked: parseBool(json['isLocked']),
        age: parseNullableInt(json['age']),
        answers: parseInterestAnswers(json['answers']),
      );

  MatchmakerInterestMatch toEntity() => MatchmakerInterestMatch(
        otherUserId: otherUserId,
        name: name,
        images: images,
        stage: stage,
        isLocked: isLocked,
        age: age,
        answers: answers,
      );
}
