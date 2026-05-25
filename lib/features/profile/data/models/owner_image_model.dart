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
        url: EndPoints.absoluteUrl(url),
        isProfile: isProfile,
        isApproved: isApproved,
      );
}
