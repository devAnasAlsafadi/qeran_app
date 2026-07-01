/// Reactive network-reachability signal for the app.
///
/// A thin, testable abstraction over the platform connectivity plugin so the
/// rest of the app depends on a plain boolean (`online`) rather than the
/// plugin's `List<ConnectivityResult>` shape. Consumers (wired in later
/// sub-steps): the HTTP layer's offline pre-flight and the connectivity
/// banner's cubit.
///
/// Note: this reports the device's *interface* state, not true reachability
/// (a device on Wi-Fi with no working uplink still reads `online`). Genuine
/// "connected-but-no-internet" cases are caught reactively at the HTTP layer.
abstract class ConnectivityService {
  /// One-shot snapshot — `true` when the platform reports at least one active,
  /// non-`none` transport.
  Future<bool> get isOnline;

  /// Distinct online/offline transitions — emits ONLY when the boolean flips,
  /// never on every raw platform event. Broadcast, so multiple consumers can
  /// listen safely.
  Stream<bool> get onStatusChange;
}
