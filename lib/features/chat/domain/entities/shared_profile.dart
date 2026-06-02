import 'package:equatable/equatable.dart';

import 'shared_profile_answer.dart';
import 'shared_profile_image.dart';

/// Mini-profile attached to a chat message via `[profile:guid]`.
///
/// Backend confirmed `placements` is currently always empty for
/// share-profile responses; we don't model it on the entity. If
/// backend ever ships placements via the chat path, we'll add an
/// optional field then.
///
/// `age` is nullable (older accounts may lack it). `matchingScore`
/// arrives as a numeric type (int or double) — we normalise to
/// double here for the UI's percent rounding. `0` means "not
/// scored" and the UI hides the chip in that case.
class SharedProfile extends Equatable {
  final String id;
  final String name;
  final int? age;
  final double matchingScore;
  final List<SharedProfileImage> images;

  /// Facts (nationality, profession, …) from `sharedProfile.answers[]`.
  /// May be empty.
  final List<SharedProfileAnswer> answers;

  const SharedProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.matchingScore,
    required this.images,
    this.answers = const [],
  });

  /// First profile-flagged image, else the first image, else null.
  SharedProfileImage? get primaryImage {
    if (images.isEmpty) return null;
    for (final img in images) {
      if (img.isProfile) return img;
    }
    return images.first;
  }

  @override
  List<Object?> get props => [id, name, age, matchingScore, images, answers];
}
