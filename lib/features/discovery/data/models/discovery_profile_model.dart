import '../../domain/entities/discovery_profile.dart';
import 'placement_model.dart';
import 'profile_image_model.dart';

class DiscoveryProfileModel {
  final String id;
  final String name;
  final int age;
  final List<ProfileImageModel> images;
  final double matchingScore;
  final List<PlacementModel> placements;

  const DiscoveryProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.images,
    required this.matchingScore,
    required this.placements,
  });

  factory DiscoveryProfileModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      images: (json['images'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProfileImageModel.fromJson)
          .toList(),
      matchingScore: ((json['matchingScore'] as num?) ?? 0).toDouble(),
      placements: (json['placements'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlacementModel.tryParse)
          .whereType<PlacementModel>()
          .toList(),
    );
  }

  DiscoveryProfile toEntity() => DiscoveryProfile(
        id: id,
        name: name,
        age: age,
        images: images.map((i) => i.toEntity()).toList(),
        matchingScore: matchingScore,
        placements: placements.map((p) => p.toEntity()).toList(),
      );
}
