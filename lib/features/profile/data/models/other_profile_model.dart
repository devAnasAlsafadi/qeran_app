import '../../domain/entities/other_profile.dart';
import '../json_parsers.dart';
import 'other_profile_image_model.dart';
import 'placement_model.dart';

class OtherProfileModel {
  final String id;
  final String name;
  final int? age;
  final double matchingScore;
  final List<OtherProfileImageModel> images;
  final List<PlacementModel> placements;

  const OtherProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.matchingScore,
    required this.images,
    required this.placements,
  });

  factory OtherProfileModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
            .whereType<Map<String, dynamic>>()
            .map(OtherProfileImageModel.fromJson)
            .toList(growable: false)
        : const <OtherProfileImageModel>[];
    final rawPlacements = json['placements'];
    final placements = rawPlacements is List
        ? rawPlacements
            .whereType<Map<String, dynamic>>()
            .map(PlacementModel.fromJson)
            .toList(growable: false)
        : const <PlacementModel>[];
    return OtherProfileModel(
      id: parseString(json['id']),
      name: parseString(json['name']),
      age: parseNullableInt(json['age']),
      matchingScore: parseDouble(json['matchingScore']),
      images: images,
      placements: placements,
    );
  }

  OtherProfile toEntity() => OtherProfile(
        id: id,
        name: name,
        age: age,
        matchingScore: matchingScore,
        images: images.map((i) => i.toEntity()).toList(growable: false),
        placements: placements.map((p) => p.toEntity()).toList(growable: false),
      );
}
