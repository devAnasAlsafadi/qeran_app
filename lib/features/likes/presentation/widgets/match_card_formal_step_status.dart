import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_case_stage.dart';

/// What a case that has travelled PAST the formal step says on its card.
///
/// Split out of `match_card_formal_step_section.dart` when that file reached
/// 186 lines and two more stage strings were due — the standing rule in this
/// folder is that the next change splits first rather than shipping at 201.
/// The section resolves WHICH of its four states applies; this answers what
/// the post-approval one puts on the card, the same division
/// `MatchCardStage0Status` already keeps beside `match_card_stage0.dart`.
///
/// Two questions, deliberately answered separately:
///   • [isPastApproval] — is the retired "awaiting their approval" button a
///     lie here? True at all three post-approval stages, because the payload
///     carries no perspective and the button would say it to both members.
///   • [text] / [icon] — what should the card say instead? Not every stage
///     that must LOSE the button has words of its own yet.
class MatchCardFormalStepStatus {
  const MatchCardFormalStepStatus._();

  /// Stages reachable only by the receiver APPROVING the step. All three,
  /// which is what makes the retired sent button wrong on all three rather
  /// than only on the newest.
  ///
  /// Exhaustive rather than a set literal: these stages shadow the ones
  /// `MatchCard.hasRequestedFormalStep` answers true for, and a twelfth
  /// stage added server-side should break the build in both places rather
  /// than quietly read as "not approved" in one of them.
  static bool isPastApproval(MatchCaseStage stage) => switch (stage) {
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

  /// The line this stage puts under the name, or null to keep the stage's
  /// own subtitle.
  ///
  /// Only the moment of approval is spoken for. «تمت الموافقة. ستتواصل معك
  /// الخطّابة» is true the instant the step is approved and the matchmaker
  /// picks the case up; by `parentsVisited` it is stale, and on
  /// `marriageCompleted` it is simply false — the marriage already happened.
  /// What those two should say instead is an open question with the owner,
  /// and answering it inside a bug fix would trade one wrong line for
  /// another. They keep their stage's own subtitle until it is settled; the
  /// button is withdrawn from them all the same, because that part is a lie
  /// at every one of the three.
  static String? text(BuildContext context, MatchCaseStage stage) =>
      _justApproved(stage)
      ? LocaleKeys.likes_matches_formal_step_approved.t(context)
      : null;

  /// Paired with [text] and null wherever it is, so a stage never draws one
  /// widget's glyph beside another's words.
  static IconData? icon(MatchCaseStage stage) =>
      _justApproved(stage) ? Icons.check_circle_outline : null;

  static bool _justApproved(MatchCaseStage stage) =>
      stage == MatchCaseStage.awaitingMatchmakerCoordination;
}
