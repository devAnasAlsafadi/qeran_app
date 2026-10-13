import 'package:qeran/core/utils/server_datetime.dart';
import 'package:qeran/core/data/display_name.dart';

import '../../domain/entities/like_request_card.dart';
import '../../domain/entities/like_request_status.dart';
import 'like_profile_image_model.dart';
import 'card_facts.dart';

class LikeRequestCardModel {
  final int likeRequestId;
  final String profileId;
  final String name;
  final LikeProfileImageModel? profileImage;
  final int? age;
  final String? residence;
  final String? job;
  final LikeRequestStatus status;
  final DateTime? createdAt;
  final int? remainingSeconds;
  final DateTime? expiresAt;
  final List<String> actions;
  final bool isLocked;

  const LikeRequestCardModel({
    required this.likeRequestId,
    required this.profileId,
    required this.name,
    required this.profileImage,
    this.age,
    this.residence,
    this.job,
    required this.status,
    required this.createdAt,
    required this.remainingSeconds,
    this.expiresAt,
    required this.actions,
    required this.isLocked,
  });

  factory LikeRequestCardModel.fromJson(Map<String, dynamic> json) {
    final image = json['profileImage'];
    final actionsRaw = json['actions'];
    final facts = CardFacts.fromJson(json);
    return LikeRequestCardModel(
      // Wire type is number; coerce defensively so a server hiccup
      // (string id, missing field) doesn't crash parsing.
      likeRequestId: (json['likeRequestId'] as num?)?.toInt() ?? 0,
      profileId: json['profileId'] as String? ?? '',
      name: parseDisplayName(json),
      profileImage: image is Map<String, dynamic>
          ? LikeProfileImageModel.fromJson(image)
          : null,
      age: facts.age,
      residence: facts.residence,
      job: facts.job,
      // Wire shape is currently `int` (0..3) but earlier docs used
      // capitalised strings — pass the raw Object so the parser can
      // dispatch on either type.
      status: likeRequestStatusFromWire(json['status']),
      createdAt: _parseIso(json['createdAt']),
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
      expiresAt: _parseIso(json['expiresAt']),
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
    age: age,
    residence: residence,
    job: job,
    status: status,
    createdAt: createdAt,
    remainingSeconds: remainingSeconds,
    expiresAt: expiresAt,
    actions: actions,
    isLocked: isLocked,
  );
}
