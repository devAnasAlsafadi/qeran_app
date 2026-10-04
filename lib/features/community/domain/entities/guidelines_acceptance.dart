/// What became of accepting the Community guidelines (contract §4.1).
enum GuidelinesAcceptance {
  /// Stored on the server, for this account on every device.
  accepted,

  /// The text changed after it was read — the client published a new
  /// version. The member reads it again and is asked again.
  outdated,
}
