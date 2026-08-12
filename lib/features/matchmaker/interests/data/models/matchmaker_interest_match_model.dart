import '../../../shared/data/json_parsers.dart';
import 'package:qeran/core/data/display_name.dart';
import '../../../users/domain/entities/matchmaker_card_answer.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_formal_request.dart';
import '../../domain/entities/matchmaker_interest_image.dart';
import '../../domain/entities/matchmaker_interest_match.dart';
import '../interest_parsers.dart';

/// Wire model for the matchmaker MatchCardDto — read-only fields only
/// (pendingPhotoExchange / conversationId ignored; the match DTO has no age).
/// Confirmed fields: otherUserId / otherUserName / images / stage (0-2) /
/// isLocked / answers / formalRequest{status,statusNameAr,statusNameEn}.
class MatchmakerInterestMatchModel {
  final String otherUserId;
  final String name;
  final List<MatchmakerInterestImage> images;
  final MatchmakerInterestMatchStage stage;
  final bool isLocked;
  final int? age;
  final List<MatchmakerCardAnswer> answers;
  final MatchmakerInterestFormalRequest? formalRequest;

  const MatchmakerInterestMatchModel({
    required this.otherUserId,
    required this.name,
    required this.images,
    required this.stage,
    required this.isLocked,
    required this.age,
    required this.answers,
    required this.formalRequest,
  });

  factory MatchmakerInterestMatchModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerInterestMatchModel(
        otherUserId: parseString(json['otherUserId'] ?? json['userId']),
        name: parseDisplayName(json, prefer: const ['otherUserName']),
        images: parseInterestImages(json['images']),
        stage: matchmakerMatchStageFromWire(json['stage']),
        isLocked: parseBool(json['isLocked']),
        age: parseNullableInt(json['age']),
        answers: parseInterestAnswers(json['answers']),
        formalRequest: _parseFormalRequest(json['formalRequest']),
      );

  static MatchmakerInterestFormalRequest? _parseFormalRequest(Object? raw) {
    final map = parseNullableMap(raw);
    if (map == null) return null;
    return MatchmakerInterestFormalRequest(
      status: parseInt(map['status']),
      statusNameAr: parseString(map['statusNameAr']),
      statusNameEn: parseString(map['statusNameEn']),
    );
  }

  MatchmakerInterestMatch toEntity() => MatchmakerInterestMatch(
        otherUserId: otherUserId,
        name: name,
        images: images,
        stage: stage,
        isLocked: isLocked,
        age: age,
        answers: answers,
        formalRequest: formalRequest,
      );
}
