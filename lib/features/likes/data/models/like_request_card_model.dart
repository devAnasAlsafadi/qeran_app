import 'package:qeran/core/utils/server_datetime.dart';

import '../../domain/entities/like_request_card.dart';
import '../../domain/entities/like_request_status.dart';
import 'like_profile_image_model.dart';

class LikeRequestCardModel {
  final int likeRequestId;
  final String profileId;
  final String name;
  final LikeProfileImageModel? profileImage;
  final LikeRequestStatus status;
  final DateTime? createdAt;
  final int? remainingSeconds;
  final List<String> actions;
  final bool isLocked;

  const LikeRequestCardModel({
    required this.likeRequestId,
    required this.profileId,
    required this.name,
    required this.profileImage,
    required this.status,
    required this.createdAt,
    required this.remainingSeconds,
    required this.actions,
    required this.isLocked,
  });

  factory LikeRequestCardModel.fromJson(Map<String, dynamic> json) {
    final image = json['profileImage'];
    final actionsRaw = json['actions'];
    return LikeRequestCardModel(
      // Wire type is number; coerce defensively so a server hiccup
      // (string id, missing field) doesn't crash parsing.
      likeRequestId: (json['likeRequestId'] as num?)?.toInt() ?? 0,
      profileId: json['profileId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profileImage: image is Map<String, dynamic>
          ? LikeProfileImageModel.fromJson(image)
          : null,
      // Wire shape is currently `int` (0..3) but earlier docs used
      // capitalised strings — pass the raw Object so the parser can
      // dispatch on either type.
      status: likeRequestStatusFromWire(json['status']),
      createdAt: _parseIso(json['createdAt']),
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
      actions: actionsRaw is List
          ? actionsRaw.whereType<String>().toList(growable: false)
          : const <String>[],
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  static DateTime? _parseIso(Object? raw) => parseServerDateTime(raw);

  LikeRequestCard toEntity() => LikeRequestCard(
        likeRequestId: likeRequestId,
        profileId: profileId,
        name: name,
        profileImage: profileImage?.toEntity(),
        status: status,
        createdAt: createdAt,
        remainingSeconds: remainingSeconds,
        actions: actions,
        isLocked: isLocked,
      );
}
