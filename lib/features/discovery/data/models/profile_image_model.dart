import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/profile_image.dart';

class ProfileImageModel {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  const ProfileImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  factory ProfileImageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['url'] as String? ?? '';
    return ProfileImageModel(
      id: json['id'] as String? ?? '',
      // Resolve the server's relative path to an absolute URL here so the
      // domain entity is always usable as-is.
      url: EndPoints.absoluteUrl(raw),
      isProfile: json['isProfile'] as bool? ?? false,
      isBlurred: json['isBlurred'] as bool? ?? false,
    );
  }

  ProfileImage toEntity() => ProfileImage(
        id: id,
        url: url,
        isProfile: isProfile,
        isBlurred: isBlurred,
      );
}
