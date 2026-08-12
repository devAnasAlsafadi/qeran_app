import 'package:equatable/equatable.dart';

/// Navigation payload for a matchmaker viewing a candidate profile.
///
/// Explore results may belong to another matchmaker. In that case the row
/// already carries the responsible matchmaker identity, so the profile can
/// offer the same colleague-chat action at its bottom without another API.
class MatchmakerUserProfileArgs extends Equatable {
  final String userId;
  final ResponsibleMatchmakerContact? responsibleMatchmaker;

  const MatchmakerUserProfileArgs({
    required this.userId,
    this.responsibleMatchmaker,
  });

  @override
  List<Object?> get props => [userId, responsibleMatchmaker];
}

class ResponsibleMatchmakerContact extends Equatable {
  final String id;
  final String name;
  final String? profileImageUrl;

  const ResponsibleMatchmakerContact({
    required this.id,
    required this.name,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [id, name, profileImageUrl];
}
