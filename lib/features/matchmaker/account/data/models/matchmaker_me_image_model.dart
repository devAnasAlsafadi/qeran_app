import 'package:qeran/core/api/end_points.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_me_image.dart';

/// Wire model for the matchmaker profile image. Serves both the `GET /me`
/// `profileImage` object `{id, url, isProfile}` and an item of the upload
/// response `{id, url, isProfile, isApproved}` (the extra `isApproved` is
/// ignored — matchmaker photos are always approved).
class MatchmakerMeImageModel {
  final String id;
  final String url;
  final bool isProfile;

  const MatchmakerMeImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
  });

  factory MatchmakerMeImageModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerMeImageModel(
        id: parseString(json['id']),
        url: parseString(json['url']),
        isProfile: parseBool(json['isProfile']),
      );

  MatchmakerMeImage toEntity() => MatchmakerMeImage(
        id: id,
        url: url.isEmpty ? url : EndPoints.absoluteUrl(url),
        isProfile: isProfile,
      );
}
