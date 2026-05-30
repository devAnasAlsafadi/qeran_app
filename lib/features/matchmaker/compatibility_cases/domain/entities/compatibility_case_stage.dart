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
