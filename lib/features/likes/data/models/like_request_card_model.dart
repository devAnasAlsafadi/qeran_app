import 'package:qeran/core/utils/server_datetime.dart';
import 'package:qeran/core/data/display_name.dart';

import '../../domain/entities/like_request_card.dart';
import '../../domain/entities/like_request_status.dart';
import 'like_profile_image_model.dart';

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
    return LikeRequestCardModel(
      // Wire type is number; coerce defensively so a server hiccup
      // (string id, missing field) doesn't crash parsing.
      likeRequestId: (json['likeRequestId'] as num?)?.toInt() ?? 0,
      profileId: json['profileId'] as String? ?? '',
      name: parseDisplayName(json),
      profileImage: image is Map<String, dynamic>
          ? LikeProfileImageModel.fromJson(image)
          : null,
      age: _age(json),
      residence: _fact(
        json,
        directKeys: const [
          'residence',
          'countryOfResidence',
          'residenceCountry',
        ],
        questionTerms: const ['إقامة', 'اقامة', 'residence'],
      ),
      job: _fact(
        json,
        directKeys: const ['job', 'occupation', 'profession'],
        questionTerms: const ['مهنة', 'وظيفة', 'job', 'occupation'],
      ),
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

  static int? _age(Map<String, dynamic> json) {
    final direct = _parseInt(json['age']);
    if (direct != null) return direct;
    final answer = _fact(
      json,
      directKeys: const [],
      questionTerms: const ['العمر', 'age'],
    );
    return _parseInt(answer);
  }

  static int? _parseInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  static String? _fact(
    Map<String, dynamic> json, {
    required List<String> directKeys,
    required List<String> questionTerms,
  }) {
    for (final key in directKeys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    final answers = json['answers'];
    if (answers is! List) return null;
    for (final raw in answers) {
      if (raw is! Map) continue;
      final question = raw['question']?.toString().toLowerCase() ?? '';
      if (!questionTerms.any(question.contains)) continue;
      final answer = raw['answer']?.toString().trim();
      if (answer != null && answer.isNotEmpty) return answer;
    }
    return null;
  }

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
