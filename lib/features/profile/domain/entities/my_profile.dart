import 'package:equatable/equatable.dart';

import 'placement.dart';
import 'profile_image.dart';
import 'profile_status.dart';

/// My own profile as returned by `GET /api/profile`. Owner-only
/// fields (email, birthDate, status, isApproved on images) live here;
/// peer-facing screens use [OtherProfile] instead.
class MyProfile extends Equatable {
  final String id;
  final String name;

  /// Legal/full name for formal proceedings. Owner-only; never shown to
  /// another user. Null until the member fills it in from profile edit.
  final String? realName;
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
