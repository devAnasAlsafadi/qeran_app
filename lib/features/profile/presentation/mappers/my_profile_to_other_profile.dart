import '../../domain/entities/my_profile.dart';
import '../../domain/entities/other_profile.dart';
import '../../domain/entities/profile_image.dart';

/// Adapts the owner's [MyProfile] into an [OtherProfile] so the shared
/// detailed-profile surface ([FullProfileBody]) can render it in self-mode.
///
/// Two self-mode rules fall out of the data, so the shared hero needs no
/// branching:
/// * `matchingScore = 0` → the hero hides the compatibility pill (you have
///   no score against yourself).
/// * every image `isBlurred = false` → the hero hides the privacy lock
///   (your own photos are never blurred to you).
///
/// `placements` pass straight through — both shapes use the same entity.
OtherProfile myProfileToOtherProfile(MyProfile profile) {
  return OtherProfile(
    id: profile.id,
    name: profile.name,
    age: profile.age > 0 ? profile.age : null,
    matchingScore: 0,
    images: profile.images
        .map(
          (img) => OtherProfileImage(
            id: img.id,
            url: img.url,
            isProfile: img.isProfile,
            isBlurred: false,
          ),
        )
        .toList(growable: false),
    placements: profile.placements,
  );
}
