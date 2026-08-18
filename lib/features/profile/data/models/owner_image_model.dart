import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/profile_image.dart';
import '../json_parsers.dart';

class OwnerImageModel {
  final String id;
  final String url;
  final bool isProfile;

  const OwnerImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
  });

  /// The wire still carries `isApproved`, but per-image review is retired
  /// server-side and it now arrives as null. Nothing reads it — deliberately
  /// not modelled, so no consumer can revive a review state that no longer
  /// exists.
  factory OwnerImageModel.fromJson(Map<String, dynamic> json) =>
      OwnerImageModel(
        id: parseString(json['id']),
        url: parseString(json['url']),
        isProfile: parseBool(json['isProfile']),
      );

  OwnerImage toEntity() => OwnerImage(
        id: id,
        // Both `GET /profile` and `GET /users/profile-images` now return the
        // url, so it is used as given — resolved against the origin when the
        // server sends a relative path. An absent url stays empty rather than
        // resolving to the bare origin: callers already treat empty as "no
        // photo" and fall back to the monogram.
        url: url.isEmpty ? '' : EndPoints.absoluteUrl(url),
        isProfile: isProfile,
      );
}
