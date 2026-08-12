import '../../domain/entities/photo_view_permission.dart';
import '../json_parsers.dart';

class PhotoViewPermissionModel {
  final String targetUserId;
  final int? photoExchangeId;
  final bool isUnblurred;
  final DateTime? viewedAt;
  final DateTime? viewExpiresAt;
  final bool isConsumed;
  final int? secondsRemaining;

  const PhotoViewPermissionModel({
    required this.targetUserId,
    required this.photoExchangeId,
    required this.isUnblurred,
    required this.viewedAt,
    required this.viewExpiresAt,
    required this.isConsumed,
    required this.secondsRemaining,
  });

  factory PhotoViewPermissionModel.fromJson(Map<String, dynamic> json) =>
      PhotoViewPermissionModel(
        targetUserId: parseString(json['targetUserId']),
        photoExchangeId: parseNullableInt(json['photoExchangeId']),
        isUnblurred: parseBool(json['isUnblurred']),
        viewedAt: parseNullableDateTime(json['viewedAt']),
        viewExpiresAt: parseNullableDateTime(json['viewExpiresAt']),
        isConsumed: parseBool(json['isConsumed']),
        secondsRemaining: parseNullableInt(json['secondsRemaining']),
      );

  PhotoViewPermission toEntity() => PhotoViewPermission(
    targetUserId: targetUserId,
    photoExchangeId: photoExchangeId,
    isUnblurred: isUnblurred,
    viewedAt: viewedAt,
    viewExpiresAt: viewExpiresAt,
    isConsumed: isConsumed,
    secondsRemaining: secondsRemaining,
  );
}
