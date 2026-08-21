import 'badge_tab_keys.dart';

/// Which bottom-nav tab acknowledges which badge, per shell.
///
/// Opening a tab IS the acknowledgement — the user looked, so the dot goes and
/// the server is told. A tab absent from a map is excluded deliberately, and
/// the two reasons are not the same:
///
///   * Discovery, Dashboard and Explore have nothing to clear. The backend
///     documents their keys as permanently zero and no dot is rendered for
///     them, so there is no acknowledgement to make.
///   * Messages and Conversations DO carry a badge, and still must not clear
///     it here. A list of conversations is not "seen" because someone looked
///     at the list; it is seen one conversation at a time, which `MarkAsRead`
///     already reports over the chat hub. Clearing on tab open would bury
///     messages nobody opened.
///
/// The indices are the bottom-nav order each shell builds. They live here
/// rather than in a switch inside the shells because neither shell can be
/// pumped in a widget test — they pull in the whole app — and the exclusions
/// above are exactly what a later edit would undo without noticing.
class NavBadgeTabs {
  const NavBadgeTabs._();

  /// Discovery (0) · Likes (1) · Messages (2) · Profile (3).
  ///
  /// Likes clears on the PARENT tab: its sub-tabs split one server count, so
  /// there is nothing finer to acknowledge.
  static const Map<int, String> user = {
    1: BadgeTabKeys.likes,
    3: BadgeTabKeys.account,
  };

  /// Dashboard (0) · Users (1) · Cases (2) · Conversations (3) · Explore (4).
  ///
  /// Users clears the nav dot only. The pending count on its «بالانتظار»
  /// segment comes from the dashboard stats and means something else entirely
  /// — a queue of work still to do, not activity since the last visit — so it
  /// survives the visit that clears the dot.
  static const Map<int, String> matchmaker = {
    1: BadgeTabKeys.users,
    2: BadgeTabKeys.cases,
  };
}
