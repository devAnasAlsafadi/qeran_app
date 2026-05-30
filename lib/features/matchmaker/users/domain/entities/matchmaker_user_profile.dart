import 'package:equatable/equatable.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/profile_image.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

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

  /// Primary photo; `null` when the user hasn't uploaded one.
  final ProfileImage? profileImage;

  /// Full gallery — already absolute + unblurred ([OwnerImage]).
  final List<ProfileImage> images;
  final List<Placement> placements;

  const MatchmakerUserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.gender,
    required this.birthDate,
    required this.age,
    required this.profileStatus,
    required this.hasAnsweredQuestions,
    required this.profileImage,
    required this.images,
    required this.placements,
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
        profileImage,
        images,
        placements,
      ];
}
