import 'package:equatable/equatable.dart';

import 'formal_request.dart';
import 'match_case_stage.dart';
import 'match_case_status.dart';
import 'match_image.dart';
import 'match_stage.dart';
import 'pending_formal_step.dart';
import 'photo_exchange_pending.dart';

/// One row in the Matches tab.
///
/// Stage drives the UI variant; `pendingPhotoExchange`, `pendingFormalStep`,
/// `formalRequest` and `conversationId` are stage-specific adornments.
/// `images` is the full ordered gallery (server pre-sorts, profile-first) —
/// the card renders the first entry and the gallery sheet renders the full
/// list.
///
/// Three fields answer three different questions and are easy to confuse:
/// [stage] is what to render NOW, [caseStage] is how far the couple got, and
/// [caseStatus] is whether it is still running.
///
/// Those three default rather than being required, unlike every other field
/// here. Several screens build a synthetic card to reuse this row's widgets —
/// the matchmaker's interest cards and the profile seed — and they have no
/// case data to give. Requiring it would make them pass filler. Cards parsed
/// from the wire always pass all three explicitly, so the real path stays
/// honest and only the synthetic ones take the default.
class MatchCard extends Equatable {
  final int likeRequestId;
  final String otherUserId;
  final String otherUserName;
  final List<MatchImage> images;
  final MatchStage stage;
  final PhotoExchangePending? pendingPhotoExchange;
  final FormalRequest? formalRequest;
  final String? conversationId;

  /// How far the journey travelled. Defaults to [MatchCaseStage.unknown].
  final MatchCaseStage caseStage;

  /// Whether it is still running. Defaults to [MatchCaseStatus.active] —
  /// an absent field means active, so a synthetic card reads as live.
  final MatchCaseStatus caseStatus;

  /// An open formal-step request, or null when none is in flight.
  final PendingFormalStep? pendingFormalStep;

  /// When anything last happened to this case — the key `/api/matches` orders
  /// by, newest first, so a card the member needs to act on rises to the top.
  ///
  /// The server moves it on every event that touches the case: the like being
  /// accepted, a photo request and its answer, a formal-step request and its
  /// answer, a matchmaker action, a cancellation. It deliberately does NOT
  /// move on expiry — a sweep marking dozens of cases expired at once would
  /// reshuffle dozens of members' lists with no real news in any of them.
  ///
  /// Null only before the field is deployed, or on a payload cached from
  /// before it shipped; existing rows were backfilled.
  final DateTime? lastActivityAt;

  const MatchCard({
    required this.likeRequestId,
    required this.otherUserId,
    required this.otherUserName,
    required this.images,
    required this.stage,
    required this.pendingPhotoExchange,
    required this.formalRequest,
    required this.conversationId,
    this.caseStage = MatchCaseStage.unknown,
    this.caseStatus = MatchCaseStatus.active,
    this.pendingFormalStep,
    this.lastActivityAt,
  });

  /// Whether THIS member has already set the formal step in motion, so the
  /// CTA should report it rather than offer to start it again.
  ///
  /// Server-derived, and that is the whole point of it. It replaces an
  /// in-memory set on `LikesState` that survived a refresh but not a restart,
  /// so a member who reopened the app was invited to request a step they had
  /// already requested.
  ///
  /// Two halves, and the second is not optional: [pendingFormalStep] goes
  /// NULL the moment the receiver approves, so reading only the block would
  /// bring the CTA back to life on a case that has already moved past it.
  ///
  /// Deliberately FALSE in three states, and what happens next differs:
  ///   • a request the OTHER member sent — "awaiting their approval" would
  ///     name the wrong person; the receiver's own card answers that. Tapping
  ///     reaches the server and gets an honest refusal back.
  ///   • a step that was DECLINED — over, not pending. Since sub-step 7 the
  ///     card offers no tap at all: a decline is one of the three endings, so
  ///     `MatchCardScaffold.isEnded` withdraws the whole primary region.
  ///   • a step that LAPSED — also over, but expiry is deliberately NOT an
  ///     ending (the matchmaker can still pick the couple up), so this one
  ///     keeps its button and still takes the refusal from the server.
  bool get hasRequestedFormalStep {
    if (pendingFormalStep?.requestedByMe == true) return true;
    return switch (caseStage) {
      MatchCaseStage.awaitingMatchmakerCoordination ||
      MatchCaseStage.parentsVisited ||
      MatchCaseStage.marriageCompleted => true,
      MatchCaseStage.likeAccepted ||
      MatchCaseStage.photoExchangePending ||
      MatchCaseStage.photoExchangeAccepted ||
      MatchCaseStage.photoExchangeRejected ||
      MatchCaseStage.photoExchangeExpired ||
      MatchCaseStage.formalStepPending ||
      MatchCaseStage.formalStepRejected ||
      MatchCaseStage.formalStepExpired ||
      MatchCaseStage.unknown => false,
    };
  }

  /// First profile image if any, else the first image, else null.
  MatchImage? get primaryImage {
    if (images.isEmpty) return null;
    for (final img in images) {
      if (img.isProfile) return img;
    }
    return images.first;
  }

  @override
  List<Object?> get props => [
        likeRequestId,
        otherUserId,
        otherUserName,
        images,
        stage,
        pendingPhotoExchange,
        formalRequest,
        conversationId,
        caseStage,
        caseStatus,
        pendingFormalStep,
        lastActivityAt,
      ];
}
