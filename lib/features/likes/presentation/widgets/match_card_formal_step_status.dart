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
///   • [forStage] — what should the card say instead? All three are spoken
///     for now, but the questions stay apart: a twelfth post-approval stage
///     added server-side must lose the button whether or not anyone has
///     written its line yet.
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

  /// The line and glyph this stage puts under the name, or null to keep the
  /// stage's own subtitle.
  ///
  /// ONE lookup returning both, never a pair of them. `MatchJourneyStep`
  /// makes the same choice for the same reason — "two properties describing
  /// one fact, resolved independently, is exactly how they come to disagree"
  /// — and here a stage wearing another stage's glyph would be the label bug
  /// this file was split out of, one field over.
  ///
  /// Exhaustive, so a twelfth server stage breaks the build in all three
  /// places that answer for it: the entity's `hasRequestedFormalStep`,
  /// [isPastApproval], and this. Reading wrong in one of the three while the
  /// other two are right is the failure this shape exists to prevent.
  ///
  /// Wine, not gold, at every one of them. Approval and marriage are the
  /// app's warmest moments and gold is how it celebrates — but the status
  /// line is not where that decision is being made, and half-celebrating the
  /// smaller milestone louder than the larger one is worse than waiting.
  static ({String text, IconData icon})? forStage(
    BuildContext context,
    MatchCaseStage stage,
  ) => switch (stage) {
    MatchCaseStage.awaitingMatchmakerCoordination => (
      text: LocaleKeys.likes_matches_formal_step_approved.t(context),
      icon: Icons.check_circle_outline,
    ),
    // The families have met. Deliberately NOT the matchmaker "arranging" a
    // meeting — that is the stage before, and saying it here would move the
    // case backwards a step. `groups_outlined` over stage 2's handshake for
    // the same reason: this is the meeting that happened, not the deal.
    MatchCaseStage.parentsVisited => (
      text: LocaleKeys.likes_matches_formal_step_parents_visited.t(context),
      icon: Icons.groups_outlined,
    ),
    // The journey, not the step. Every other line here reports on the formal
    // step; this one closes the whole case, which is why it borrows stage
    // 1's own success glyph rather than continuing the formal-step series.
    MatchCaseStage.marriageCompleted => (
      text: LocaleKeys.likes_matches_formal_step_marriage_completed.t(context),
      icon: Icons.favorite_rounded,
    ),
    MatchCaseStage.likeAccepted ||
    MatchCaseStage.photoExchangePending ||
    MatchCaseStage.photoExchangeAccepted ||
    MatchCaseStage.photoExchangeRejected ||
    MatchCaseStage.photoExchangeExpired ||
    MatchCaseStage.formalStepPending ||
    MatchCaseStage.formalStepRejected ||
    MatchCaseStage.formalStepExpired ||
    MatchCaseStage.unknown => null,
  };
}
