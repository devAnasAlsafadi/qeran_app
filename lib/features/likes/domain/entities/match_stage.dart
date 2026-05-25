/// Lifecycle stage of an active match from the server.
///
/// Stable wire values per backend: 0/1/2. `unknown` is a defensive
/// fallback so a future server-side addition doesn't crash the UI —
/// the card layer renders a neutral shell for it.
enum MatchStage {
  /// Stage 0 — like was accepted, photos still blurred.
  /// Available action: request photo exchange (initiator path).
  waitingForPhotoExchange,

  /// Stage 1 — photos exchanged, both sides unblurred. The matchmaker
  /// owns the next move; a formalRequest may be attached.
  photosExchanged,

  /// Stage 2 — photo exchange was rejected OR the matchmaker engaged
  /// directly. Photos remain blurred. NOT archived.
  matchmakerEngaged,

  /// Defensive — unrecognised server value.
  unknown;

  static MatchStage fromCode(Object? raw) {
    final code = switch (raw) {
      int n => n,
      String s => int.tryParse(s),
      _ => null,
    };
    return switch (code) {
      0 => MatchStage.waitingForPhotoExchange,
      1 => MatchStage.photosExchanged,
      2 => MatchStage.matchmakerEngaged,
      _ => MatchStage.unknown,
    };
  }
}
