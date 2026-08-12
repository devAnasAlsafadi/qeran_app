import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/data/display_name.dart';
import 'package:qeran/core/enum/gender.dart';

import '../../../shared/data/json_parsers.dart';
import '../../../users/domain/entities/matchmaker_card_answer.dart';
import '../../domain/entities/matchmaker_explore_user.dart';

/// Wire model for one `MatchmakerExploreUserDto` row. Defensive throughout —
/// `gender` tolerates "Male"/"Female"/null, `age` is null when absent, and
/// `answers` is `[]` (never null) via `parseMapList`. The relative image path
/// is absolutized in [toEntity] so the avatar only ever sees a ready URL.
class MatchmakerExploreUserModel {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final String? gender;
  final String? assignedMatchmakerId;
  final String? assignedMatchmakerName;

  /// RAW relative path — absolutized in [toEntity]. Null today (backend doesn't
  /// send it yet); kept defensive so it lights up automatically when added.
  final String? assignedMatchmakerImageUrl;

  final bool isMyAssigned;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerExploreUserModel({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.gender,
    required this.assignedMatchmakerId,
    required this.assignedMatchmakerName,
    required this.assignedMatchmakerImageUrl,
    required this.isMyAssigned,
    required this.age,
    required this.answers,
  });

  factory MatchmakerExploreUserModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerExploreUserModel(
        userId: parseString(json['userId']),
        fullName: parseDisplayName(json),
        profileImageUrl: parseNullableString(json['profileImageUrl']),
        gender: parseNullableString(json['gender']),
        assignedMatchmakerId:
            parseNullableString(json['assignedMatchmakerId']),
        assignedMatchmakerName:
            parseNullableString(json['assignedMatchmakerName']),
        assignedMatchmakerImageUrl:
            parseNullableString(json['assignedMatchmakerImageUrl']),
        isMyAssigned: parseBool(json['isMyAssigned']),
        age: parseNullableInt(json['age']),
        answers: parseMapList(json['answers'])
            .map(
              (a) => MatchmakerCardAnswer(
                questionId: parseInt(a['questionId']),
                question: parseString(a['question']),
                answer: parseString(a['answer']),
              ),
            )
            .toList(growable: false),
      );

  MatchmakerExploreUser toEntity() {
    final raw = profileImageUrl;
    return MatchmakerExploreUser(
      userId: userId,
      fullName: fullName,
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      gender: Gender.fromString(gender),
      assignedMatchmakerId: assignedMatchmakerId,
      assignedMatchmakerName: assignedMatchmakerName,
      assignedMatchmakerImageUrl:
          (assignedMatchmakerImageUrl == null ||
                  assignedMatchmakerImageUrl!.isEmpty)
              ? null
              : EndPoints.absoluteUrl(assignedMatchmakerImageUrl!),
      isMyAssigned: isMyAssigned,
      age: age,
      answers: answers,
    );
  }
}
