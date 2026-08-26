/// Lifecycle stage of a compatibility case, parsed from the `stage` string
/// on `GET /api/matchmaker/compatibility-cases`. This is the matchmaker
/// case's OWN stage enum — distinct from the likes-module `MatchStage`.
///
/// Eleven server values in journey order. The first five are the original
/// photo-exchange track; the six after them arrived with the interactive
/// journey (V2), where the formal step became a two-party request instead of
/// a chat message.
///
/// A `formalRequest` is non-null from [awaitingMatchmakerCoordination] onward
/// — the server creates it when the RECEIVER approves the formal step, not
/// when photos are exchanged. Unknown wire values fall back to [unknown] so a
/// new server stage never collapses the card.
enum CompatibilityCaseStage {
  likeAccepted,
  photoExchangePending,
  photoExchangeAccepted,
  photoExchangeRejected,
  photoExchangeExpired,

  /// The formal step was requested and the RECEIVER has not answered yet.
  /// Nothing for the matchmaker to do — it is the other member's turn.
  formalStepPending,

  /// The receiver declined the formal step. The case ends here.
  formalStepRejected,

  /// Nobody answered the formal step inside its window.
  formalStepExpired,

  /// The receiver approved. The matchmaker now arranges the family meeting;
  /// this is where a `formalRequest` starts existing.
  awaitingMatchmakerCoordination,

  parentsVisited,
  marriageCompleted,
  unknown;

  /// The exact name `GET /api/matchmaker/compatibility-cases?stage=` expects.
  ///
  /// The server takes an integer too, and this used to send 0..4 — which is the
  /// dangerous option. A .NET string enum binds a number by ORDINAL, so if the
  /// server ever inserts or reorders a member, every request keeps returning
  /// 200 with cases from the wrong stage. Nothing surfaces: no error, no empty
  /// list, just quietly incorrect results. The name cannot drift that way — an
  /// unrecognised one is a loud 400.
  ///
  /// These are the eleven values in the server's own `CompatibilityCaseStage`
  /// schema, and each is exactly this enum's member name in PascalCase. The
  /// filter sheet currently offers only the first five; the rest are here so
  /// the mapping stays total, not because anything sends them yet.
  String? get apiValue => switch (this) {
    likeAccepted => 'LikeAccepted',
    photoExchangePending => 'PhotoExchangePending',
    photoExchangeAccepted => 'PhotoExchangeAccepted',
    photoExchangeRejected => 'PhotoExchangeRejected',
    photoExchangeExpired => 'PhotoExchangeExpired',
    formalStepPending => 'FormalStepPending',
    formalStepRejected => 'FormalStepRejected',
    formalStepExpired => 'FormalStepExpired',
    awaitingMatchmakerCoordination => 'AwaitingMatchmakerCoordination',
    parentsVisited => 'ParentsVisited',
    marriageCompleted => 'MarriageCompleted',
    // Not a server value — a tolerated unknown from the response side, never
    // something to filter BY.
    unknown => null,
  };

  static CompatibilityCaseStage fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'likeaccepted':
        return CompatibilityCaseStage.likeAccepted;
      case 'photoexchangepending':
        return CompatibilityCaseStage.photoExchangePending;
      case 'photoexchangeaccepted':
        return CompatibilityCaseStage.photoExchangeAccepted;
      case 'photoexchangerejected':
        return CompatibilityCaseStage.photoExchangeRejected;
      case 'photoexchangeexpired':
        return CompatibilityCaseStage.photoExchangeExpired;
      case 'formalsteppending':
        return CompatibilityCaseStage.formalStepPending;
      case 'formalsteprejected':
        return CompatibilityCaseStage.formalStepRejected;
      case 'formalstepexpired':
        return CompatibilityCaseStage.formalStepExpired;
      case 'awaitingmatchmakercoordination':
        return CompatibilityCaseStage.awaitingMatchmakerCoordination;
      case 'parentsvisited':
        return CompatibilityCaseStage.parentsVisited;
      case 'marriagecompleted':
        return CompatibilityCaseStage.marriageCompleted;
      default:
        return CompatibilityCaseStage.unknown;
    }
  }
}
