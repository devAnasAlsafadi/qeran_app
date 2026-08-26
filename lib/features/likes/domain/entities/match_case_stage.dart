/// How far the compatibility case has travelled, as the member's matches feed
/// carries it (`caseStage` on `/api/matches`).
///
/// This is the journey position, and it is NOT [MatchStage]. The two arrive on
/// the same row and answer different questions: `stage` says what the card
/// should render right now (three values, unchanged), `caseStage` says how far
/// the couple actually got (eleven). Reading one where the other was meant is
/// the mistake this doc exists to prevent.
///
/// Deliberately a likes-module enum rather than an import of the matchmaker's
/// `CompatibilityCaseStage`, which carries these same eleven values. Likes
/// imports nothing from matchmaker, and `MatchFormalStatus` already mirrors
/// `FormalRequestStatus` for the same reason — each module owns its own view
/// of the wire.
///
/// ⚠️ These codes are **0-based** — `LikeAccepted` is 0. The `formalRequest`
/// status codes on this same payload are **1-based**. Two adjacent enums, two
/// different bases; an off-by-one between them raises nothing anywhere and
/// simply puts the member on the wrong node.
enum MatchCaseStage {
  likeAccepted,
  photoExchangePending,
  photoExchangeAccepted,
  photoExchangeRejected,
  photoExchangeExpired,

  /// The formal step was asked for and the receiver has not answered.
  formalStepPending,

  /// The receiver declined. The case ends here.
  formalStepRejected,

  /// Nobody answered inside the window.
  formalStepExpired,

  /// The receiver approved and the matchmaker is arranging the meeting.
  awaitingMatchmakerCoordination,

  parentsVisited,
  marriageCompleted,

  /// Defensive — an unrecognised value. Never a reason to hide the journey.
  unknown;

  /// Parse the wire `caseStage`, tolerant of both shapes:
  ///   • enum-name string (current): `"AwaitingMatchmakerCoordination"`, …
  ///   • numeric code: `0`..`10` (int, or a numeric string).
  ///
  /// Both are accepted for the same reason `MatchStage` accepts both: this
  /// field has been observed flipping shape on other endpoints, and a flip
  /// that silently drops every row to [unknown] costs more than a switch arm.
  static MatchCaseStage fromWire(Object? raw) {
    if (raw is String) {
      switch (raw.toLowerCase()) {
        case 'likeaccepted':
          return MatchCaseStage.likeAccepted;
        case 'photoexchangepending':
          return MatchCaseStage.photoExchangePending;
        case 'photoexchangeaccepted':
          return MatchCaseStage.photoExchangeAccepted;
        case 'photoexchangerejected':
          return MatchCaseStage.photoExchangeRejected;
        case 'photoexchangeexpired':
          return MatchCaseStage.photoExchangeExpired;
        case 'formalsteppending':
          return MatchCaseStage.formalStepPending;
        case 'formalsteprejected':
          return MatchCaseStage.formalStepRejected;
        case 'formalstepexpired':
          return MatchCaseStage.formalStepExpired;
        case 'awaitingmatchmakercoordination':
          return MatchCaseStage.awaitingMatchmakerCoordination;
        case 'parentsvisited':
          return MatchCaseStage.parentsVisited;
        case 'marriagecompleted':
          return MatchCaseStage.marriageCompleted;
      }
    }
    final code = switch (raw) {
      int n => n,
      String s => int.tryParse(s),
      _ => null,
    };
    if (code == null || code < 0 || code >= MatchCaseStage.unknown.index) {
      return MatchCaseStage.unknown;
    }
    return MatchCaseStage.values[code];
  }
}
