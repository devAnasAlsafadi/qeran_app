import 'package:equatable/equatable.dart';

import 'case_chat.dart';
import 'case_formal_request.dart';
import 'case_photo_exchange.dart';
import 'case_user.dart';
import 'compatibility_case_stage.dart';

/// A denormalized compatibility case between two users, as returned by
/// `GET /api/matchmaker/compatibility-cases`. Carries both participants,
/// the photo-exchange sub-state, the formal-request sub-state (null until
/// the case reaches the formal track), the chat ids (M4), and whether this
/// matchmaker may drive the formal-request status (3b).
class CompatibilityCase extends Equatable {
  final int caseId;
  final CaseUser myUser;
  final CaseUser otherUser;
  final DateTime? likeAcceptedAt;
  final CompatibilityCaseStage stage;
  final CasePhotoExchange? photoExchange;
  final CaseFormalRequest? formalRequest;
  final CaseChat chat;
  final bool canUpdateFormalRequestStatus;

  const CompatibilityCase({
    required this.caseId,
    required this.myUser,
    required this.otherUser,
    required this.likeAcceptedAt,
    required this.stage,
    required this.photoExchange,
    required this.formalRequest,
    required this.chat,
    required this.canUpdateFormalRequestStatus,
  });

  @override
  List<Object?> get props => [
        caseId,
        myUser,
        otherUser,
        likeAcceptedAt,
        stage,
        photoExchange,
        formalRequest,
        chat,
        canUpdateFormalRequestStatus,
      ];
}
