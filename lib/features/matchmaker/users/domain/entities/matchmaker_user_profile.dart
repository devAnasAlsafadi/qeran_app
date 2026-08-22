import 'package:equatable/equatable.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/profile_image.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import 'assigned_matchmaker.dart';
import 'image_request_status.dart';

/// A user's full profile as seen by the matchmaker
/// (`GET /api/matchmaker/users/{id}/profile`). This is the owner-ish shape:
/// it carries [email], [gender] and [profileStatus] and has no matching
/// score (the matchmaker isn't being matched against the user). Images are
/// always unblurred — they parse to [OwnerImage], which the shared gallery
/// never blurs.
///
/// Rendering reuses the profile feature's [Placement] / [ProfileImage]
/// entities and their renderers, so the read surface is identical to the
/// user-side full profile.
class MatchmakerUserProfile extends Equatable {
  final String userId;
  final String name;
  final String email;

  /// Localised display string straight from the server (e.g. "أنثى").
  final String gender;
  final DateTime? birthDate;
  final int? age;
  final ProfileStatus profileStatus;
  final bool hasAnsweredQuestions;

  /// Whether this profile belongs to the signed-in matchmaker. A profile can
  /// also be opened from discovery/interests, where it must stay read-only.
  final bool isAssignedToMe;

  /// Primary photo; `null` when the user hasn't uploaded one.
  final ProfileImage? profileImage;

  /// Full gallery — already absolute + unblurred ([OwnerImage]).
  final List<ProfileImage> images;
  final List<Placement> placements;

  /// Whether the matchmaker already asked this user for a photo. Defaults to
  /// [MatchmakerImageRequestStatus.none] when the server omits the field.
  final MatchmakerImageRequestStatus imageRequestStatus;

  /// Who this user belongs to. Null when nobody is assigned — and the profile
  /// is reachable from paths where that is normal, so absence is not an error.
  final AssignedMatchmaker? assignedMatchmaker;

  const MatchmakerUserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.gender,
    required this.birthDate,
    required this.age,
    required this.profileStatus,
    required this.hasAnsweredQuestions,
    required this.isAssignedToMe,
    required this.profileImage,
    required this.images,
    required this.placements,
    this.imageRequestStatus = MatchmakerImageRequestStatus.none,
    this.assignedMatchmaker,
  });

  @override
  List<Object?> get props => [
    userId,
    name,
    email,
    gender,
    birthDate,
    age,
    profileStatus,
    hasAnsweredQuestions,
    isAssignedToMe,
    profileImage,
    images,
    placements,
    imageRequestStatus,
    assignedMatchmaker,
  ];
}
