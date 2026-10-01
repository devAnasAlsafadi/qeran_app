import 'package:equatable/equatable.dart';

/// Who wrote a Community post, comment or reply (contract §2.1).
///
/// [displayName] only — the real name never reaches Community.
/// [profileImageUrl] is null for every member (D10); for a matchmaker it is
/// `/api/community/avatars/{userId}`: Bearer-protected and never blurred, so
/// it must not go through the profile-photo blur widgets.
class CommunityAuthor extends Equatable {
  final String id;
  final String displayName;
  final bool isMatchmaker;
  final String? profileImageUrl;

  const CommunityAuthor({
    required this.id,
    required this.displayName,
    required this.isMatchmaker,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [id, displayName, isMatchmaker, profileImageUrl];
}
