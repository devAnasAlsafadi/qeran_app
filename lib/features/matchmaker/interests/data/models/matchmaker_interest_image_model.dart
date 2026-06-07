import 'package:qeran/core/api/end_points.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_interest_image.dart';

/// Wire model for ProfileImageDto {id, url, isProfile, isBlurred}.
class MatchmakerInterestImageModel {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  const MatchmakerInterestImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  factory MatchmakerInterestImageModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerInterestImageModel(
        id: parseString(json['id']),
        url: parseString(json['url']),
        isProfile: parseBool(json['isProfile']),
        isBlurred: parseBool(json['isBlurred']),
      );

  MatchmakerInterestImage toEntity() => MatchmakerInterestImage(
        id: id,
        url: url.isEmpty ? url : EndPoints.absoluteUrl(url),
        isProfile: isProfile,
        isBlurred: isBlurred,
      );
}
