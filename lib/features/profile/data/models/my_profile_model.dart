import '../../domain/entities/my_profile.dart';
import 'package:qeran/core/data/display_name.dart';
import '../../domain/entities/profile_status.dart';
import '../json_parsers.dart';
import 'owner_image_model.dart';
import 'placement_model.dart';

class MyProfileModel {
  final String userId;
  final String name;

  /// Legal/full name, collected for formal proceedings. Owner-only —
  /// never present on another user's payload and never rendered publicly.
  final String? realName;

  /// The server assigned the placeholder name and the member has never chosen
  /// one. Prompts them to set a real one; it does not restrict editing.
  final bool isDefaultName;
  final String? email;
  final String gender;
  final DateTime? birthDate;
  final int age;
  final String profileStatus;
  final bool hasAnsweredQuestions;
  final OwnerImageModel? profileImage;
  final List<OwnerImageModel> images;
  final List<PlacementModel> placements;

  const MyProfileModel({
    required this.userId,
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

  factory MyProfileModel.fromJson(Map<String, dynamic> json) {
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
    final pImage = json['profileImage'];
    return MyProfileModel(
      // Backend ships `userId` here; accept `id` as a forward-compat
      // alias if the field ever renames.
      userId: parseString(json['userId'] ?? json['id']),
      name: parseDisplayName(json),
      realName: parseNullableString(json['realName']),
      isDefaultName: parseBool(json['isDefaultName']),
      email: parseNullableString(json['email']),
      gender: parseString(json['gender']),
      birthDate: parseNullableDateTime(json['birthDate']),
      age: parseInt(json['age']),
      profileStatus: parseString(json['profileStatus']),
      hasAnsweredQuestions: parseBool(json['hasAnsweredQuestions']),
      profileImage: pImage is Map<String, dynamic>
          ? OwnerImageModel.fromJson(pImage)
          : null,
      images: images,
      placements: placements,
    );
  }

  MyProfile toEntity() => MyProfile(
        id: userId,
        name: name,
        realName: realName,
        isDefaultName: isDefaultName,
        email: email,
        gender: gender,
        birthDate: birthDate,
        age: age,
        profileStatus: ProfileStatus.fromString(profileStatus),
        hasAnsweredQuestions: hasAnsweredQuestions,
        profileImage: profileImage?.toEntity(),
        images: images.map((i) => i.toEntity()).toList(growable: false),
        placements: placements.map((p) => p.toEntity()).toList(growable: false),
      );
}
