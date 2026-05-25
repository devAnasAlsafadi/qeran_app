import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/shared_profile_image.dart';
import '../json_parsers.dart';

class SharedProfileImageModel {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  const SharedProfileImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  factory SharedProfileImageModel.fromJson(Map<String, dynamic> json) {
    return SharedProfileImageModel(
      id: parseString(json['id']),
      url: parseString(json['url']),
      isProfile: parseBool(json['isProfile']),
      // Privacy-safe default — if backend ever omits this, we blur.
      isBlurred: parseBool(json['isBlurred'], fallback: true),
    );
  }

  SharedProfileImage toEntity() => SharedProfileImage(
        id: id,
        url: url.isEmpty ? '' : EndPoints.absoluteUrl(url),
        isProfile: isProfile,
        isBlurred: isBlurred,
      );
}
