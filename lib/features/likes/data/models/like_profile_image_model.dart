import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/like_profile_image.dart';

class LikeProfileImageModel {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  const LikeProfileImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  factory LikeProfileImageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['url'] as String? ?? '';
    return LikeProfileImageModel(
      id: json['id'] as String? ?? '',
      // The server returns a relative path like
      // `/api/users/profile-images/{id}`. Resolve to an absolute URL
      // here so the entity is renderable as-is.
      url: EndPoints.absoluteUrl(raw),
      isProfile: json['isProfile'] as bool? ?? false,
      isBlurred: json['isBlurred'] as bool? ?? false,
    );
  }

  LikeProfileImage toEntity() => LikeProfileImage(
        id: id,
        url: url,
        isProfile: isProfile,
        isBlurred: isBlurred,
      );
}
