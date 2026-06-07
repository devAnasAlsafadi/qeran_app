import 'package:equatable/equatable.dart';
import 'package:qeran/core/enum/gender.dart';

import '../../../users/domain/entities/matchmaker_card_answer.dart';

/// A card-like explore result from `GET /api/matchmaker/explore`
/// (`MatchmakerExploreUserDto`) — NOT a full profile. Carries just enough to
/// render a user card: identity, photo, age, the admin-flagged [answers], and
/// the assignment hints. [profileImageUrl] is already absolute (the data layer
/// runs the server's relative path through `EndPoints.absoluteUrl`). [answers]
/// reuses the read-only [MatchmakerCardAnswer] (the same `{questionId, question,
/// answer}` shape as the user-list cards); `[]`, never null, when none.
///
/// Tapping a card opens the existing full-profile-by-id screen (works for any
/// user) — this DTO is the list payload, not the detail.
class MatchmakerExploreUser extends Equatable {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final Gender? gender;
  final String? assignedMatchmakerId;
  final String? assignedMatchmakerName;
  final bool isMyAssigned;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerExploreUser({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.gender,
    required this.assignedMatchmakerId,
    required this.assignedMatchmakerName,
    required this.isMyAssigned,
    required this.age,
    required this.answers,
  });

  @override
  List<Object?> get props => [
        userId,
        fullName,
        profileImageUrl,
        gender,
        assignedMatchmakerId,
        assignedMatchmakerName,
        isMyAssigned,
        age,
        answers,
      ];
}
