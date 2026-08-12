import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/data/display_name.dart';
import 'package:qeran/core/utils/server_datetime.dart';

import '../../domain/entities/blocked_user.dart';

/// Wire model for a `GET /api/block` row: `{userId, name, imageUrl(null for
/// now), blockedAt}`. Parsing is defensive (`name ?? fullName`) — CODE WINS
/// over the assumed shape.
class BlockedUserModel {
  final String userId;
  final String name;
  final String? imageUrl;
  final DateTime? blockedAt;

  const BlockedUserModel({
    required this.userId,
    required this.name,
    this.imageUrl,
    this.blockedAt,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    final rawImage = (json['imageUrl'] ?? json['image']) as String?;
    return BlockedUserModel(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      name: parseDisplayName(json),
      imageUrl: (rawImage == null || rawImage.isEmpty)
          ? null
          : EndPoints.absoluteUrl(rawImage),
      blockedAt: parseServerDateTime(json['blockedAt']),
    );
  }

  BlockedUser toEntity() => BlockedUser(
        userId: userId,
        name: name,
        imageUrl: imageUrl,
        blockedAt: blockedAt,
      );
}
