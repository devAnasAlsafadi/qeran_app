/// Where a bottom-nav tab was reached FROM, when it was reached by something
/// other than a nav tap — and therefore where "back" should go.
///
/// One nullable field rather than a flag per source, so that a tab can only
/// ever have been arrived at from one place: a second source replaces the
/// first instead of leaving two back controls with no defined winner.
///
/// Null is the ordinary case: the tab was tapped, and back keeps its default
/// meaning.
enum HomeBackTrail {
  /// From the notifications inbox — a row tapped there, or a system push
  /// tapped outside the app. Going back REOPENS the inbox rather than popping
  /// to it: the route is destroyed on the way to a tab, and never existed at
  /// all on the push path.
  notifications,
}
