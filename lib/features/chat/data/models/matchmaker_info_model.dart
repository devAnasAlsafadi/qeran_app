import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/matchmaker_info.dart';
import '../json_parsers.dart';

class MatchmakerInfoModel {
  final String matchmakerId;
  final String name;
  final String? profileImageUrl;
  final int conversationId;

  const MatchmakerInfoModel({
    required this.matchmakerId,
    required this.name,
    required this.profileImageUrl,
    required this.conversationId,
  });

  factory MatchmakerInfoModel.fromJson(Map<String, dynamic> json) {
    return MatchmakerInfoModel(
      matchmakerId: parseString(json['matchmakerId']),
      name: parseString(json['name']),
      profileImageUrl: parseNullableString(json['profileImageUrl']),
      conversationId: parseInt(json['conversationId']),
    );
  }

  MatchmakerInfo toEntity() {
    final raw = profileImageUrl;
    return MatchmakerInfo(
      matchmakerId: matchmakerId,
      name: name,
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      conversationId: conversationId,
    );
  }
}
