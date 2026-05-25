import '../../domain/entities/shared_profile.dart';
import '../json_parsers.dart';
import 'shared_profile_image_model.dart';

class SharedProfileModel {
  final String id;
  final String name;
  final int? age;
  final double matchingScore;
  final List<SharedProfileImageModel> images;

  const SharedProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.matchingScore,
    required this.images,
  });

  static SharedProfileModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return SharedProfileModel(
      id: parseString(raw['id']),
      name: parseString(raw['name']),
      age: parseNullableInt(raw['age']),
      matchingScore: parseDouble(raw['matchingScore']),
      images: _parseImages(raw['images']),
    );
  }

  static List<SharedProfileImageModel> _parseImages(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SharedProfileImageModel.fromJson)
        .toList(growable: false);
  }

  SharedProfile toEntity() => SharedProfile(
        id: id,
        name: name,
        age: age,
        matchingScore: matchingScore,
        images: images.map((m) => m.toEntity()).toList(growable: false),
      );
}
