/// The three segments on the Likes / Interests screen.
///
/// Order is conceptual (not visual). Visual order in the segmented
/// control is decided inside `LikesSegmentedTabs` and respects the
/// app's RTL layout.
enum LikesTab {
  /// Users I've already sent a like to. Status defaults to `pending`.
  sent,

  /// Users who sent me a like. Each card shows accept / reject actions
  /// when the item is still `pending`.
  received,

  /// Active matches (post-like-acceptance) across all stages 0/1/2:
  /// awaiting photo exchange, photos exchanged, and matchmaker
  /// engaged. Archived matches are NOT shown here.
  matches,
}
