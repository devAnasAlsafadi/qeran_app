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
  });

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
      ];
}
