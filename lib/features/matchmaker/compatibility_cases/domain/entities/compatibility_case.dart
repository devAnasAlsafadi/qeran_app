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

  /// Whether THIS matchmaker has a private note on the case (drives the
  /// list-card notes-chip indicator). Strictly per-matchmaker — never
  /// reflects a colleague's note.
  final bool hasMyNote;

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
    required this.hasMyNote,
  });

  /// Direct chat is valid only for a user currently assigned to this
  /// matchmaker. An external participant is contacted through their
  /// matchmaker instead.
  bool get canMessageOtherUser =>
      otherUser.isAssignedToMe && otherUser.userId.isNotEmpty;

  /// Show the colleague action only for an external participant whose
  /// matchmaker id is available.
  bool get canMessageOtherMatchmaker =>
      !otherUser.isAssignedToMe &&
      (chat.otherMatchmakerId?.isNotEmpty ?? false);

  /// Minimal additive copy — [formalRequest] supports the live
  /// `CompatibilityCaseUpdated` flow (4c); [hasMyNote] supports the in-place
  /// notes-indicator update after the note sheet saves/deletes (M3-notes).
  /// All other fields are carried through.
  CompatibilityCase copyWith({
    CaseFormalRequest? formalRequest,
    bool? hasMyNote,
    bool? canUpdateFormalRequestStatus,
  }) {
    return CompatibilityCase(
      caseId: caseId,
      myUser: myUser,
      otherUser: otherUser,
      likeAcceptedAt: likeAcceptedAt,
      stage: stage,
      photoExchange: photoExchange,
      formalRequest: formalRequest ?? this.formalRequest,
      chat: chat,
      canUpdateFormalRequestStatus:
          canUpdateFormalRequestStatus ?? this.canUpdateFormalRequestStatus,
      hasMyNote: hasMyNote ?? this.hasMyNote,
    );
  }

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
    hasMyNote,
  ];
}
