/// Outcome of a "start over" that the deck itself cannot show.
///
/// A reset that restored someone reloads the deck, and the returning cards are
/// their own feedback — nothing lands here. Everything else leaves the screen
/// looking untouched, which reads as a broken button unless we say what
/// happened.
///
/// Deliberately its own channel rather than borrowing the like/pass
/// `actionError`: that path renders a generic "something went wrong" because a
/// like failure's server message is not trusted, which would throw away the
/// specific copy this action has.
///
/// Carries the OUTCOME, not a message — the copy and the snackbar severity are
/// the view's business.
enum DiscoveryResetNotice {
  /// The reset succeeded and there was nothing to undo: the user had skipped
  /// nobody. Not an error.
  nothingToRestore,

  /// The request failed. The skips are untouched, so retrying is safe.
  failed,

  /// The device reported no connectivity, which deserves its own copy rather
  /// than a generic failure.
  offline,
}
