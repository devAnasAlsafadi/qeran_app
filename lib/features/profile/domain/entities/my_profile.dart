import 'package:equatable/equatable.dart';

import 'placement.dart';
import 'profile_image.dart';
import 'profile_status.dart';

/// My own profile as returned by `GET /api/profile`. Owner-only
/// fields (email, birthDate, status) live here; peer-facing screens
/// use [OtherProfile] instead.
class MyProfile extends Equatable {
  final String id;

  /// The DISPLAY name — what other members see. Resolved through
  /// `parseDisplayName`, which never falls back to [realName].
  final String name;

  /// Legal/full name for formal proceedings. Owner-only — never shown to
  /// another user and never carried on a peer payload. Editable by the member
  /// alongside [name]; null while they have not set one.
  final String? realName;

  /// The display name is still the server-assigned placeholder, so the member
  /// has never chosen one. Drives the prompt to set a real one; it does not
  /// restrict editing.
  final bool isDefaultName;
  final String? email;
  final String gender;
  final DateTime? birthDate;
  final int age;
  final ProfileStatus profileStatus;
  final bool hasAnsweredQuestions;
  final OwnerImage? profileImage;
  final List<OwnerImage> images;
  final List<Placement> placements;

  const MyProfile({
    required this.id,
    required this.name,
    this.realName,
    this.isDefaultName = false,
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
        id,
        name,
        realName,
        isDefaultName,
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
