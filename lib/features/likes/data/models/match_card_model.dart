import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_case_stage.dart';
import '../../domain/entities/match_case_status.dart';
import '../../domain/entities/match_stage.dart';
import '../json_parsers.dart';
import 'formal_request_model.dart';
import 'match_image_model.dart';
import 'pending_formal_step_model.dart';
import 'photo_exchange_pending_model.dart';

class MatchCardModel {
  final int likeRequestId;
  final String otherUserId;
  final String otherUserName;
  final List<MatchImageModel> images;
  final MatchStage stage;
  final PhotoExchangePendingModel? pendingPhotoExchange;
  final FormalRequestModel? formalRequest;
  final String? conversationId;
  final MatchCaseStage caseStage;
  final MatchCaseStatus caseStatus;
  final PendingFormalStepModel? pendingFormalStep;
  final DateTime? lastActivityAt;

  const MatchCardModel({
    required this.likeRequestId,
    required this.otherUserId,
    required this.otherUserName,
    required this.images,
    required this.stage,
    required this.pendingPhotoExchange,
    required this.formalRequest,
    required this.conversationId,
    required this.caseStage,
    required this.caseStatus,
    required this.pendingFormalStep,
    required this.lastActivityAt,
  });

  factory MatchCardModel.fromJson(Map<String, dynamic> json) {
    return MatchCardModel(
      likeRequestId: parseInt(json['likeRequestId']),
      otherUserId: parseString(json['otherUserId']),
      otherUserName: parseString(json['otherUserName']),
      images: _parseImages(json['images']),
      stage: MatchStage.fromWire(json['stage']),
      pendingPhotoExchange:
          PhotoExchangePendingModel.fromJson(json['pendingPhotoExchange']),
      formalRequest: FormalRequestModel.fromJson(json['formalRequest']),
      conversationId: parseNullableString(json['conversationId']),
      caseStage: MatchCaseStage.fromWire(json['caseStage']),
      caseStatus: MatchCaseStatus.fromWire(json['caseStatus']),
      pendingFormalStep:
          PendingFormalStepModel.fromJson(json['pendingFormalStep']),
      // Through the shared server-date parser, never DateTime.parse: that one
      // reads an unmarked timestamp as DEVICE-LOCAL, which would shift the
      // ordering key by the member's UTC offset. Tariq's converter marks every
      // date it emits, so this is the belt to that braces — and it is the
      // difference between an ordering key and a guess.
      lastActivityAt: parseNullableDateTime(json['lastActivityAt']),
    );
  }

  static List<MatchImageModel> _parseImages(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MatchImageModel.fromJson)
        .toList(growable: false);
  }

  MatchCard toEntity() => MatchCard(
        likeRequestId: likeRequestId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        images: images.map((m) => m.toEntity()).toList(growable: false),
        stage: stage,
        pendingPhotoExchange: pendingPhotoExchange?.toEntity(),
        formalRequest: formalRequest?.toEntity(),
        conversationId: conversationId,
        // Always explicit from the wire — the entity's defaults exist for the
        // synthetic cards other features build, not for this path.
        caseStage: caseStage,
        caseStatus: caseStatus,
        pendingFormalStep: pendingFormalStep?.toEntity(),
        lastActivityAt: lastActivityAt,
      );
}
