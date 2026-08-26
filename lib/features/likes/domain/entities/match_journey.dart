import 'match_card.dart';
import 'match_case_stage.dart';
import 'match_formal_status.dart';
import 'match_stage.dart';

/// The compatibility journey as the MEMBER sees it: five nodes, strictly
/// linear, no branches.
///
/// These are the SAME five the matchmaker's `CaseStage` carries, and that is
/// now the point rather than a coincidence — one couple, one position, whoever
/// is looking. The member's wording differs (the matchmaker's nodes name steps
/// they work), but the placement cannot: two screens disagreeing about how far
/// along a case is has no innocent reading.
///
/// The old projection had a sixth opening node for the like itself and folded
/// both formal steps into a single "the matchmaker is following up". It also
/// folded every failure in there, which is why this projection still has no
/// "ended" outcome at all where the matchmaker's has four.
enum MatchJourneyStage {
  /// The like is accepted and the journey has begun. Reachable as the CURRENT
  /// node — unlike the opening node of the projection this replaced.
  initialCompatibility,

  /// The photo exchange is the live step, whatever it is doing there:
  /// requested, agreed, declined, or lapsed.
  photoExchange,

  /// The formal step is the live step — asked for, answered, or being
  /// arranged by the matchmaker.
  formalContact,

  /// The matchmaker recorded the family meeting.
  formalMeeting,

  /// The marriage went ahead. The only terminal node.
  marriageCompleted,
}

/// Where [card] currently stands on the journey.
///
/// Driven by `caseStage`, the server's own answer to this exact question, so
/// the member's timeline and the matchmaker's read one field rather than each
/// deriving a position from parts. The eleven server stages collapse onto the
/// five nodes exactly as the matchmaker's `caseStagePlacement` collapses them.
///
/// The switch is exhaustive on purpose: a new server stage should break the
/// build here rather than quietly render the wrong node.
MatchJourneyStage matchJourneyStage(MatchCard card) => switch (card.caseStage) {
  MatchCaseStage.likeAccepted => MatchJourneyStage.initialCompatibility,

  // All four photo states sit on the photo node. Which of them it is changes
  // the TONE and the label, not the position — and both of those arrive with
  // the outcome, not here.
  MatchCaseStage.photoExchangePending ||
  MatchCaseStage.photoExchangeAccepted ||
  MatchCaseStage.photoExchangeRejected ||
  MatchCaseStage.photoExchangeExpired => MatchJourneyStage.photoExchange,

  // Same for the formal step, coordination included: the matchmaker arranging
  // the meeting is still the formal-contact step, not the meeting itself.
  MatchCaseStage.formalStepPending ||
  MatchCaseStage.formalStepRejected ||
  MatchCaseStage.formalStepExpired ||
  MatchCaseStage.awaitingMatchmakerCoordination =>
    MatchJourneyStage.formalContact,

  MatchCaseStage.parentsVisited => MatchJourneyStage.formalMeeting,
  MatchCaseStage.marriageCompleted => MatchJourneyStage.marriageCompleted,

  MatchCaseStage.unknown => _fromOlderFields(card),
};

/// Placement for a row whose `caseStage` we cannot read — absent, or a value
/// this build has never heard of.
///
/// The obvious alternative was to send [MatchCaseStage.unknown] to the first
/// node, which is what the matchmaker does. On the member's screen that would
/// visibly REVERSE a journey: a couple whose families have met would find
/// themselves back at the beginning because one string changed spelling. So
/// this reconstructs the position from `formalRequest` and `stage` — the two
/// fields the journey ran on before `caseStage` existed, and the reason
/// `formalRequest` still has a reader.
MatchJourneyStage _fromOlderFields(MatchCard card) {
  final formal = card.formalRequest;
  if (formal != null) {
    return switch (MatchFormalStatus.fromWire(formal.status)) {
      MatchFormalStatus.successfullyClosed => MatchJourneyStage.marriageCompleted,
      MatchFormalStatus.parentsVisited => MatchJourneyStage.formalMeeting,
      // Both closures anchor to the formal-contact node, exactly as
      // `caseStagePlacement` anchors them to its first formal stage. A
      // formalRequest exists, so the formal track is where the couple got to;
      // whether it ended there is the outcome's business, not the position's.
      MatchFormalStatus.waitingForParentAppointment ||
      MatchFormalStatus.compatibilityClosed ||
      MatchFormalStatus.compatibilityCancelled ||
      MatchFormalStatus.unknown => MatchJourneyStage.formalContact,
    };
  }

  return switch (card.stage) {
    // The pending block's own status is deliberately not read. Accepted and
    // rejected are already expressed by the server moving `stage`, and every
    // other value — pending, lapsed, expired, unrecognised — means the same
    // thing here: the exchange step is under way.
    MatchStage.waitingForPhotoExchange => card.pendingPhotoExchange == null
        ? MatchJourneyStage.initialCompatibility
        : MatchJourneyStage.photoExchange,

    // Photos through, or the exchange declined, and no formalRequest: nobody
    // has started the formal step. These used to reach the merged follow-up
    // node, which under the interactive journey would announce a step neither
    // member has taken — so they stay on the photo node, matching where
    // `photoExchangeAccepted` and `photoExchangeRejected` land above.
    MatchStage.photosExchanged ||
    MatchStage.matchmakerEngaged => MatchJourneyStage.photoExchange,

    // Nothing on the row is recognisable. The one thing it still proves is
    // that a like was accepted — a match card exists — so that is the only
    // claim this makes.
    MatchStage.unknown => MatchJourneyStage.initialCompatibility,
  };
}
