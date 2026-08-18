import 'package:qeran/features/profile/data/models/owner_image_model.dart';
import 'package:qeran/core/data/display_name.dart';
import 'package:qeran/features/profile/data/models/placement_model.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/image_request_status.dart';
import '../../domain/entities/matchmaker_user_profile.dart';

/// Wire model for the matchmaker profile-detail payload — the object found
/// at `data.data.data` (the datasource unwraps the double envelope before
/// this runs). Scalars use the matchmaker module's parsers; the nested
/// `images` and `placements` reuse the profile feature's parsers so the
/// shape stays in lock-step with the user-side profile.
///
/// Images parse as [OwnerImageModel], yielding [OwnerImage], which the gallery
/// renders unblurred.
class MatchmakerUserProfileModel {
  final String userId;
  final String name;
  final String email;
  final String gender;
  final DateTime? birthDate;
  final int? age;
  final String profileStatus;
  final bool hasAnsweredQuestions;
  final bool isAssignedToMe;
  final OwnerImageModel? profileImage;
  final List<OwnerImageModel> images;
  final List<PlacementModel> placements;

  /// Raw wire value — `"none" | "pending" | "approved"`. Kept as the string
  /// the server sent; [toEntity] does the typing.
  final String? imageRequestStatus;

  const MatchmakerUserProfileModel({
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
    required this.imageRequestStatus,
  });

  factory MatchmakerUserProfileModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
              .whereType<Map<String, dynamic>>()
              .map(OwnerImageModel.fromJson)
              .toList(growable: false)
        : const <OwnerImageModel>[];
    final rawPlacements = json['placements'];
    final placements = rawPlacements is List
        ? rawPlacements
              .whereType<Map<String, dynamic>>()
              .map(PlacementModel.fromJson)
              .toList(growable: false)
        : const <PlacementModel>[];
    final rawProfileImage = json['profileImage'];
    return MatchmakerUserProfileModel(
      userId: parseString(json['userId']),
      name: parseDisplayName(json),
      email: parseString(json['email']),
      gender: parseString(json['gender']),
      birthDate: parseNullableDateTime(json['birthDate']),
      age: parseNullableInt(json['age']),
      profileStatus: parseString(json['profileStatus']),
      hasAnsweredQuestions: parseBool(json['hasAnsweredQuestions']),
      // Fail closed for old/malformed payloads: without an explicit true the
      // profile is view-only and no mutation affordance is installed.
      isAssignedToMe: parseBool(json['isAssignedToMe']),
      profileImage: rawProfileImage is Map<String, dynamic>
          ? OwnerImageModel.fromJson(rawProfileImage)
          : null,
      images: images,
      placements: placements,
      imageRequestStatus: parseNullableString(json['imageRequestStatus']),
    );
  }

  MatchmakerUserProfile toEntity() => MatchmakerUserProfile(
    userId: userId,
    name: name,
    email: email,
    gender: gender,
    birthDate: birthDate,
    age: age,
    profileStatus: ProfileStatus.fromString(profileStatus),
    hasAnsweredQuestions: hasAnsweredQuestions,
    isAssignedToMe: isAssignedToMe,
    profileImage: profileImage?.toEntity(),
    images: images.map((i) => i.toEntity()).toList(growable: false),
    placements: placements.map((p) => p.toEntity()).toList(growable: false),
    imageRequestStatus: MatchmakerImageRequestStatus.fromString(
      imageRequestStatus,
    ),
  );
}
