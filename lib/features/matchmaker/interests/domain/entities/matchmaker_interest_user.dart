import 'package:equatable/equatable.dart';

/// The page subject (the `user` header on every MatchmakerUserPageDto) — the
/// assigned user whose interests the matchmaker is viewing. Rendered once above
/// the tabs. [profileImageUrl] is absolute; `null` when none.
class MatchmakerInterestUser extends Equatable {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final int? age;

  const MatchmakerInterestUser({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    this.age,
  });

  @override
  List<Object?> get props => [userId, fullName, profileImageUrl, age];
}
