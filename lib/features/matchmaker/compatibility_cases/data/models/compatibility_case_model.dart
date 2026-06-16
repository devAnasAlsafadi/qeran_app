import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/compatibility_case_stage.dart';
import 'case_chat_model.dart';
import 'case_formal_request_model.dart';
import 'case_photo_exchange_model.dart';
import 'case_user_model.dart';

/// Wire model for a single denormalized case in the
/// `GET /api/matchmaker/compatibility-cases` list. Nested objects go
/// through [parseNullableMap] so a `Map<dynamic,dynamic>` from any decode
/// path still parses; `photoExchange` and `formalRequest` are nullable
/// (the latter is `null` until the case reaches the formal track).
class CompatibilityCaseModel {
  final int caseId;
  final CaseUserModel myUser;
  final CaseUserModel otherUser;
  final DateTime? likeAcceptedAt;
  final String stage;
  final CasePhotoExchangeModel? photoExchange;
  final CaseFormalRequestModel? formalRequest;
  final CaseChatModel chat;
  final bool canUpdateFormalRequestStatus;
  final bool hasMyNote;

  const CompatibilityCaseModel({
    required this.caseId,
    required this.myUser,
    required this.otherUser,
    required this.likeAcceptedAt,
    required this.stage,
    required this.photoExchange,
    required this.formalRequest,
    required this.chat,
    required this.canUpdateFormalRequestStatus,
    required this.hasMyNote,
  });

  factory CompatibilityCaseModel.fromJson(Map<String, dynamic> json) {
    final photoExchange = parseNullableMap(json['photoExchange']);
    final formalRequest = parseNullableMap(json['formalRequest']);
    return CompatibilityCaseModel(
      caseId: parseInt(json['caseId']),
      myUser: CaseUserModel.fromJson(
        parseNullableMap(json['myUser']) ?? const <String, dynamic>{},
      ),
      otherUser: CaseUserModel.fromJson(
        parseNullableMap(json['otherUser']) ?? const <String, dynamic>{},
      ),
      likeAcceptedAt: parseNullableDateTime(json['likeAcceptedAt']),
      stage: parseString(json['stage']),
      photoExchange: photoExchange == null
          ? null
          : CasePhotoExchangeModel.fromJson(photoExchange),
      formalRequest: formalRequest == null
          ? null
          : CaseFormalRequestModel.fromJson(formalRequest),
      chat: CaseChatModel.fromJson(
        parseNullableMap(json['chat']) ?? const <String, dynamic>{},
      ),
      canUpdateFormalRequestStatus:
          parseBool(json['canUpdateFormalRequestStatus']),
      hasMyNote: parseBool(json['hasMyNote']),
    );
  }

  CompatibilityCase toEntity() => CompatibilityCase(
        caseId: caseId,
        myUser: myUser.toEntity(),
        otherUser: otherUser.toEntity(),
        likeAcceptedAt: likeAcceptedAt,
        stage: CompatibilityCaseStage.fromString(stage),
        photoExchange: photoExchange?.toEntity(),
        formalRequest: formalRequest?.toEntity(),
        chat: chat.toEntity(),
        canUpdateFormalRequestStatus: canUpdateFormalRequestStatus,
        hasMyNote: hasMyNote,
      );
}
