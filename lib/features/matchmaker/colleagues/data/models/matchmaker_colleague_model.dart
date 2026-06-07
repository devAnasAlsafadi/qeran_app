import 'package:qeran/core/api/end_points.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_colleague.dart';

/// Wire model for one row of `GET /api/matchmaker/colleagues`.
///
/// Parses DEFENSIVELY per the code-wins conflict noted in the close-out plan:
/// the OLD doc shows colleague conversations as nested (`name` /
/// `userProfileImage{}`), but the live server uses the flat shape the shipped
/// user-conversation model reads. So this prefers `matchmakerId` / `name`
/// (the doc's directory keys) but falls back to `userId` / `fullName`, and
/// reads a flat `profileImageUrl`. The relative image path is absolutized in
/// [toEntity] so the avatar only ever sees a ready URL.
class MatchmakerColleagueModel {
  final String matchmakerId;
  final String name;
  final String? profileImageUrl;
  final int? conversationId;

  const MatchmakerColleagueModel({
    required this.matchmakerId,
    required this.name,
    required this.profileImageUrl,
    required this.conversationId,
  });

  factory MatchmakerColleagueModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerColleagueModel(
        matchmakerId:
            parseString(json['matchmakerId'] ?? json['userId'] ?? json['id']),
        name: parseString(json['name'] ?? json['fullName']),
        profileImageUrl: parseNullableString(json['profileImageUrl']),
        conversationId: parseNullableInt(json['conversationId']),
      );

  MatchmakerColleague toEntity() {
    final raw = profileImageUrl;
    return MatchmakerColleague(
      matchmakerId: matchmakerId,
      name: name,
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      conversationId: conversationId,
    );
  }
}
