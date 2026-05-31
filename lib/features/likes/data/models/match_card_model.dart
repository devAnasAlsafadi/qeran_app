import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_stage.dart';
import '../json_parsers.dart';
import 'formal_request_model.dart';
import 'match_image_model.dart';
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

  const MatchCardModel({
    required this.likeRequestId,
    required this.otherUserId,
    required this.otherUserName,
    required this.images,
    required this.stage,
    required this.pendingPhotoExchange,
    required this.formalRequest,
    required this.conversationId,
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
      );
}
