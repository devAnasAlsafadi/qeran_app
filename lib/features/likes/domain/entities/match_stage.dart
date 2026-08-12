/// Lifecycle stage of an active match from the server.
///
/// The `/api/matches` `stage` field is an enum-NAME string
/// (`WaitingForPhotoExchange` / `PhotosExchanged` / `MatchmakerEngaged`).
/// Older builds sent the numeric code 0/1/2; [fromWire] accepts BOTH so a
/// wire-shape flip never silently drops the row to [unknown]. `unknown`
/// is a defensive fallback so a future server-side addition doesn't crash
/// the UI — the card layer renders a neutral shell for it.
enum MatchStage {
  /// Stage 0 — like was accepted, photos still blurred.
  /// Available action: request photo exchange (initiator path).
  waitingForPhotoExchange,

  /// Stage 1 — photo exchange accepted. Each side gets one server-enforced
  /// viewing window; a formalRequest may be attached.
  photosExchanged,

  /// Stage 2 — photo exchange was rejected OR the matchmaker engaged
  /// directly. Photos remain blurred. NOT archived.
  matchmakerEngaged,

  /// Defensive — unrecognised server value.
  unknown;

  /// Parse the wire `stage`, tolerant of both shapes:
  ///   • enum-name string (current): `"WaitingForPhotoExchange"`, …
  ///   • numeric code (legacy): `0` / `1` / `2` (int or numeric string).
  /// Anything unrecognised → [unknown].
  static MatchStage fromWire(Object? raw) {
    if (raw is String) {
      switch (raw.toLowerCase()) {
        case 'waitingforphotoexchange':
          return MatchStage.waitingForPhotoExchange;
        case 'photosexchanged':
          return MatchStage.photosExchanged;
        case 'matchmakerengaged':
          return MatchStage.matchmakerEngaged;
      }
    }
    // Legacy numeric shape (int, or a numeric string like "0").
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
