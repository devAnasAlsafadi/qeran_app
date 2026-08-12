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
        // Both `GET /profile` and `GET /users/profile-images` now return the
        // url, so it is used as given — resolved against the origin when the
        // server sends a relative path. An absent url stays empty rather than
        // resolving to the bare origin: callers already treat empty as "no
        // photo" and fall back to the monogram.
        url: url.isEmpty ? '' : EndPoints.absoluteUrl(url),
        isProfile: isProfile,
        isApproved: isApproved,
      );
}
