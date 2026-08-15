/// Lifecycle stage of a compatibility case, parsed from the `stage` string
/// on `GET /api/matchmaker/compatibility-cases`. This is the matchmaker
/// case's OWN stage enum — distinct from the likes-module `MatchStage`.
///
/// A `formalRequest` is non-null only at [photoExchangeAccepted] and
/// [photoExchangeRejected]; the other stages precede or short-circuit the
/// formal track. Unknown wire values fall back to [unknown] so a new
/// server stage never collapses the card.
enum CompatibilityCaseStage {
  likeAccepted,
  photoExchangePending,
  photoExchangeAccepted,
  photoExchangeRejected,
  photoExchangeExpired,
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
  /// These are the five values in the server's own `CompatibilityCaseStage`
  /// schema, verified against the published swagger, and each is exactly this
  /// enum's member name in PascalCase.
  String? get apiValue => switch (this) {
    likeAccepted => 'LikeAccepted',
    photoExchangePending => 'PhotoExchangePending',
    photoExchangeAccepted => 'PhotoExchangeAccepted',
    photoExchangeRejected => 'PhotoExchangeRejected',
    photoExchangeExpired => 'PhotoExchangeExpired',
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
      default:
        return CompatibilityCaseStage.unknown;
    }
  }
}
