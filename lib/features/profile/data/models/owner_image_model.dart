import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/profile_image.dart';
import '../json_parsers.dart';

class OwnerImageModel {
  final String id;
  final String url;
  final bool isProfile;
  final bool isApproved;

  const OwnerImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isApproved,
  });

  factory OwnerImageModel.fromJson(Map<String, dynamic> json) {
    return OwnerImageModel(
      id: parseString(json['id']),
      url: parseString(json['url']),
      isProfile: parseBool(json['isProfile']),
      isApproved: parseBool(json['isApproved']),
    );
  }

  OwnerImage toEntity() => OwnerImage(
        id: id,
        // `GET /users/profile-images` currently omits `url` entirely, while
        // `GET /profile` returns the same ids with a full URL — so the
        // canonical location is derived from the id when the server leaves
        // it out. The moment the field is populated the real value wins and
        // this fallback goes dormant.
        url: url.isEmpty
            ? '${EndPoints.baseUrl}${EndPoints.profileImage(id)}'
            : EndPoints.absoluteUrl(url),
        isProfile: isProfile,
        isApproved: isApproved,
      );
}
