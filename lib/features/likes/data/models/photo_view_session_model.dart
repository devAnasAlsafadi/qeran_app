import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/photo_view_session.dart';
import '../json_parsers.dart';

class PhotoViewSessionModel {
  final int photoExchangeId;
  final DateTime viewedAt;
  final DateTime viewExpiresAt;
  final int secondsRemaining;

  const PhotoViewSessionModel({
    required this.photoExchangeId,
    required this.viewedAt,
    required this.viewExpiresAt,
    required this.secondsRemaining,
  });

  factory PhotoViewSessionModel.fromJson(Map<String, dynamic> json) {
    final viewedAt = parseNullableDateTime(json['viewedAt']);
    final viewExpiresAt = parseNullableDateTime(json['viewExpiresAt']);
    if (viewedAt == null || viewExpiresAt == null) {
      throw ServerException(message: LocaleKeys.errors_invalid_server_response);
    }
    return PhotoViewSessionModel(
      photoExchangeId: parseInt(json['photoExchangeId']),
      viewedAt: viewedAt,
      viewExpiresAt: viewExpiresAt,
      secondsRemaining: parseInt(json['secondsRemaining']),
    );
  }

  PhotoViewSession toEntity() => PhotoViewSession(
    photoExchangeId: photoExchangeId,
    viewedAt: viewedAt,
    viewExpiresAt: viewExpiresAt,
    secondsRemaining: secondsRemaining,
  );
}
