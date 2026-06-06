/// Where the user opened the Full Profile Details screen from.
///
/// Drives which affordances appear:
/// * pass/like floating actions   → only for `discovery`
/// * share-with-matchmaker button → discovery, likes, matches
/// * edit-answers button          → only for `mine`
///
/// Keep entries lower-camelCase to match the Dart enum style; no
/// stringly-typed comparisons elsewhere in the code base.
enum ProfileEntrySource {
  discovery,
  chat,
  likes,
  matches,
  settings,
  mine,
}
