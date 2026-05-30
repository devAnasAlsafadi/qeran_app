/// SignalR connection lifecycle for the matchmaker-owned realtime
/// connection.
///
/// A standalone mirror of the chat module's `RealtimeStatus`, kept
/// matchmaker-local on purpose: the matchmaker realtime layer shares no
/// code (and no behavioral coupling) with the user-side chat realtime
/// layer (Approach B / full isolation).
enum MatchmakerRealtimeStatus {
  /// Not yet connected, or intentionally disconnected.
  disconnected,

  /// First connect attempt or post-disconnect reconnect.
  connecting,

  /// Live; events will flow.
  connected,

  /// Mid-reconnect after a transient failure (socket drop, network blip).
  reconnecting,
}
