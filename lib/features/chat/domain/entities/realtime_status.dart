/// SignalR connection lifecycle. Drives the small banner on top of
/// the conversation screen and the cubit's catch-up behavior.
enum RealtimeStatus {
  /// Not yet connected, or intentionally disconnected (screen popped /
  /// app backgrounded for the cooldown window).
  disconnected,

  /// First connect attempt or post-disconnect reconnect.
  connecting,

  /// Live; events will flow.
  connected,

  /// Mid-reconnect after transient failure (sock drop, network blip).
  reconnecting,
}
