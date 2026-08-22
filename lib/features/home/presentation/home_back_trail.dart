/// Where a bottom-nav tab was reached FROM, when it was reached by something
/// other than a nav tap — and therefore where "back" should go.
///
/// One nullable field rather than a flag per source. A tab can only have been
/// arrived at from one place, so two booleans would make an impossible state
/// representable: land on Messages from a notification, walk to Likes, send an
/// inquiry, and both would be true with two back controls and no defined
/// winner. Here the second trail simply replaces the first.
///
/// Null is the ordinary case: the tab was tapped, and back keeps its default
/// meaning.
enum HomeBackTrail {
  /// From the notifications inbox — a row tapped there, or a system push
  /// tapped outside the app. Going back REOPENS the inbox rather than popping
  /// to it: the route is destroyed on the way to a tab, and never existed at
  /// all on the push path.
  notifications,

  /// From the Likes tab's compatibility list — sending an inquiry or taking
  /// the formal step switches to Messages so the posted card is visible.
  /// Going back is a tab switch, since nothing was pushed.
  likes,
}
