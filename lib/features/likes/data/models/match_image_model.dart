import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/match_image.dart';
import '../json_parsers.dart';

class MatchImageModel {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  const MatchImageModel({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  factory MatchImageModel.fromJson(Map<String, dynamic> json) {
    return MatchImageModel(
      id: parseString(json['id']),
      url: parseString(json['url']),
      isProfile: parseBool(json['isProfile']),
      isBlurred: parseBool(json['isBlurred'], fallback: true),
    );
  }

  /// Resolves the relative server URL to an absolute one at the
  /// model→entity boundary so the UI never has to think about it.
  MatchImage toEntity() => MatchImage(
        id: id,
        url: url.isEmpty ? '' : EndPoints.absoluteUrl(url),
        isProfile: isProfile,
        isBlurred: isBlurred,
      );
}
