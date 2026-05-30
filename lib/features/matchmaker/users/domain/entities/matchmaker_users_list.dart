/// The three matchmaker user lists, each backed by its own endpoint.
/// Drives the Users-tab segmented control and the dashboard card
/// shortcuts.
enum MatchmakerUsersList {
  pending,
  approvedUnsubscribed,
  approvedSubscribed,
}
