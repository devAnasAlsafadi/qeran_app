import 'package:equatable/equatable.dart';

import 'placement.dart';
import 'profile_image.dart';

/// Another user's profile as returned by
/// `GET /api/discovery/profiles/{userId}`. The seed-only variant
/// (constructed from Discovery/Chat/Likes/Matches previews) reuses the
/// same class with empty `placements`.
class OtherProfile extends Equatable {
  final String id;
  final String name;
  final int? age;
  final double matchingScore;
  final List<OtherProfileImage> images;
  final List<Placement> placements;

  const OtherProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.matchingScore,
    required this.images,
    required this.placements,
  });

  /// First profile-flagged image, else the first image, else null.
  /// Defensive — most rows have exactly one primary, but the contract
  /// permits zero or many.
  OtherProfileImage? get primaryImage {
    if (images.isEmpty) return null;
    for (final img in images) {
      if (img.isProfile) return img;
    }
    return images.first;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        matchingScore,
        images,
        placements,
      ];
}
