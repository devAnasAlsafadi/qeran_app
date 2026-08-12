import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/data/blurred_image_url.dart';

import '../../domain/entities/profile_image.dart';
import '../json_parsers.dart';

class OtherProfileImageModel {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;
  final String? blurredUrl;
  final String? blurredThumbnailUrl;

  const OtherProfileImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
    this.blurredUrl,
    this.blurredThumbnailUrl,
  });

  factory OtherProfileImageModel.fromJson(Map<String, dynamic> json) {
    return OtherProfileImageModel(
      id: parseString(json['id']),
      url: parseString(json['url']),
      isProfile: parseBool(json['isProfile']),
      isBlurred: parseBool(json['isBlurred'], fallback: true),
      blurredUrl: parseBlurredUrl(json['blurredUrl']),
      blurredThumbnailUrl: parseBlurredUrl(json['blurredThumbnailUrl']),
    );
  }

  OtherProfileImage toEntity() => OtherProfileImage(
        id: id,
        url: EndPoints.absoluteUrl(url),
        isProfile: isProfile,
        isBlurred: isBlurred,
        blurredUrl: blurredUrl,
        blurredThumbnailUrl: blurredThumbnailUrl,
      );
}
