import 'package:equatable/equatable.dart';

import 'placement.dart';
import 'profile_image.dart';

class DiscoveryProfile extends Equatable {
  final String id;
  final String name;
  final int age;
  final List<ProfileImage> images;

  /// Server-computed compatibility score (0–100). Stored but NOT rendered
  /// in this phase — held for analytics / future surfaces.
  final double matchingScore;

  /// Sections to render. The data layer preserves server order; UI maps
  /// `placement.code` to the appropriate position on the card / sheet.
  final List<Placement> placements;

  const DiscoveryProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.images,
    required this.matchingScore,
    required this.placements,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        images,
        matchingScore,
        placements,
      ];
}
