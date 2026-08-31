import 'match_card.dart';
import 'match_case_stage.dart';
import 'match_case_status.dart';
import 'match_formal_status.dart';

/// Whether the journey has STOPPED — the single "ended" outcome this
/// projection carries, against the matchmaker's four.
///
/// THREE endings qualify, and the narrowness is the entire rule:
///   • the member ended the case themselves, from the header X — `Cancelled`.
///   • the matchmaker recorded «لم ينجح» — `Failed`.
///   • the receiver declined the formal step — `formalStepRejected`.
///
/// All three arrive on `caseStatus`. Declining the formal step sets
/// `Cancelled` just as cancelling does, and MOVES the stage to
/// `formalStepRejected` as well — so the stage clause below is redundant
/// against a current server. It is kept deliberately, not by oversight: a
/// second independent reading of the same fact, for the price of one
/// comparison.
///
/// ⚠️ That redundancy does NOT extend to the legacy fallback, which is
/// load-bearing. A row old enough to carry no `caseStatus` reads as `active`,
/// and its ending survives only in `formalRequest.status`. Deleting that one
/// loses endings; deleting the stage clause loses only the belt to the braces.
///
/// ⚠️ Deliberately NOT [MatchCaseStatus.isEnded]. That getter also covers
/// [MatchCaseStatus.completed] — the marriage — which is the SUCCESS ending,
/// drawn by the terminal node rather than by this. Swapping the two would put
/// a danger cross on a wedding.
///
/// Everything else keeps the journey running, and each exclusion is
/// load-bearing rather than an oversight:
///   • a rejected or lapsed photo exchange — the matchmaker takes the couple
///     over and carries on, which is the case the old blanket rule existed to
///     protect and the reason this revision is narrow.
///   • a lapsed formal step — same: nobody has said no, and the matchmaker
///     can still pick it up.
///   • [MatchCaseStatus.unknown] — a status the server sent that this build
///     has never heard of. It omits rather than guesses, which is also what
///     `MatchCardCancelAction.isAvailable` does with it: the two are the only
///     member-side readers of this field, and neither treats "unrecognised"
///     as a fact about the case.
bool matchJourneyHasEnded(MatchCard card) {
  if (card.caseStatus == MatchCaseStatus.cancelled ||
      card.caseStatus == MatchCaseStatus.failed) {
    return true;
  }
  // Redundant against a current server: declining sets `Cancelled`, so the
  // clause above already caught this. Kept as a second independent reading —
  // read the doc above before removing it.
  if (card.caseStage == MatchCaseStage.formalStepRejected) return true;
  return card.caseStage == MatchCaseStage.unknown && _endedInOlderFields(card);
}

/// The same endings as spelled by the field that predates `caseStatus`.
///
/// Consulted only when `caseStage` is unreadable, exactly as the placement's
/// own `_fromOlderFields` is, and for the same reason: a row old enough to
/// carry no readable stage may
/// also predate `caseStatus` entirely, which [MatchCaseStatus.fromWire] reads
/// as `active`. Without this, those two closures would be the one place a
/// genuinely ended case still drew as live — and `formalRequest` would go back
/// to being data nothing acts on.
///
/// Exhaustive like every other switch here: a new formal status should break
/// the build rather than quietly read as a running case.
bool _endedInOlderFields(MatchCard card) {
  final formal = card.formalRequest;
  if (formal == null) return false;
  return switch (MatchFormalStatus.fromWire(formal.status)) {
    // The wire direction is confirmed against the backend: CompatibilityClosed
    // is the matchmaker's «لم ينجح» and CompatibilityCancelled is a called-off
    // case — the same two endings `caseStatus` spells Failed and Cancelled.
    MatchFormalStatus.compatibilityClosed ||
    MatchFormalStatus.compatibilityCancelled => true,
    // SuccessfullyClosed is an ending too, but the successful one: the fold
    // above already sends it to the terminal node that draws it that way.
    MatchFormalStatus.successfullyClosed ||
    MatchFormalStatus.waitingForParentAppointment ||
    MatchFormalStatus.parentsVisited ||
    MatchFormalStatus.unknown => false,
  };
}
