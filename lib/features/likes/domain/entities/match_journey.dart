import 'match_card.dart';
import 'match_formal_status.dart';
import 'match_stage.dart';

/// The compatibility journey as the MEMBER sees it: five nodes, strictly
/// linear, no branches.
///
/// This is NOT the matchmaker's `CaseStage`, and the difference is the point.
/// The matchmaker's five split the formal track into "awaiting the parents'
/// appointment" and "parents visited", because those are the steps they work.
/// A member has nothing to do with either, so both collapse into
/// [matchmakerFollowUp] — and so does every failure. A rejected photo
/// exchange, a closed case, a cancelled one: the matchmaker picks it up and
/// keeps going, so the member sees the journey continue rather than a cross
/// through it.
///
/// The practical consequence is that this projection has no "ended" outcome
/// at all, where the matchmaker's has four. Only [completed] is terminal.
enum MatchJourneyStage {
  /// Never the CURRENT stage — a match card exists only because a like was
  /// sent AND accepted, so this node is always already behind the member. It
  /// is here to give the journey a beginning, not to be arrived at.
  liked,

  /// The like is accepted and nothing else has happened yet.
  likeAccepted,

  /// A photo-exchange request is open, or its window has lapsed.
  photoExchange,

  /// The matchmaker is carrying it: photos are through, or the formal track
  /// is under way, or something ended and they took over.
  matchmakerFollowUp,

  /// The formal request closed successfully. The only terminal node.
  completed,
}

/// Where [card] currently stands on the journey.
///
/// Precedence mirrors the matchmaker's `caseStagePlacement` — the formal
/// request wins when there is one, otherwise the stage — so the two views of
/// the same couple can never disagree about how far along they are.
///
/// Both switches are exhaustive on purpose: a new server value should break
/// the build here rather than quietly render the wrong node.
MatchJourneyStage matchJourneyStage(MatchCard card) {
  final formal = card.formalRequest;
  if (formal != null) {
    return switch (MatchFormalStatus.fromWire(formal.status)) {
      MatchFormalStatus.successfullyClosed => MatchJourneyStage.completed,
      // Everything else — including both closures — reads as "the matchmaker
      // is on it". Closed and cancelled are the business rule doing its work:
      // the member is never shown a dead end.
      MatchFormalStatus.waitingForParentAppointment ||
      MatchFormalStatus.parentsVisited ||
      MatchFormalStatus.compatibilityClosed ||
      MatchFormalStatus.compatibilityCancelled ||
      MatchFormalStatus.unknown => MatchJourneyStage.matchmakerFollowUp,
    };
  }

  return switch (card.stage) {
    // The pending block's own status is deliberately not read. Accepted and
    // rejected are already expressed by the server moving `stage`, and every
    // other value — pending, lapsed, expired, unrecognised — means the same
    // thing here: the exchange step is under way.
    MatchStage.waitingForPhotoExchange =>
      card.pendingPhotoExchange == null
          ? MatchJourneyStage.likeAccepted
          : MatchJourneyStage.photoExchange,
    // Photos are through but no formal request exists yet: the formal track
    // is what happens next, and it is the matchmaker who starts it.
    MatchStage.photosExchanged ||
    // Already the matchmaker's, either because the exchange was rejected or
    // because they engaged directly.
    MatchStage.matchmakerEngaged ||
    // An unrecognised stage still means an active match, and the safe thing
    // to say about an active match is that the matchmaker is following up.
    MatchStage.unknown => MatchJourneyStage.matchmakerFollowUp,
  };
}
