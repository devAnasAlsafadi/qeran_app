import '../entities/compatibility_case_update.dart';
import '../entities/matchmaker_realtime_status.dart';

/// Domain contract for the matchmaker-owned realtime layer.
///
/// A SEPARATE connection from the user-side chat realtime port (Approach
/// B / full isolation): it targets the same hub URL with the same auth,
/// but owns its own `HubConnection`, broadcast streams, and lifecycle —
/// so nothing here can change chat behavior. Receive-only by design;
/// outbound actions still go through REST.
///
/// 4c-1 exposes only the `CompatibilityCaseUpdated` event.
/// `ReceiveMessage` (conversations-list liveness) is deferred to 4c-2.
abstract class MatchmakerRealtimePort {
  /// Latest known status (synchronous read for lifecycle decisions, e.g.
  /// the shell's resume-reconnect check).
  MatchmakerRealtimeStatus get status;

  /// Status transitions: disconnected → connecting → connected ↔
  /// reconnecting → disconnected.
  Stream<MatchmakerRealtimeStatus> get statusStream;

  /// `CompatibilityCaseUpdated` event. Consumers map `newStatus` →
  /// `FormalRequestStatus` and update the cases list in place.
  Stream<CompatibilityCaseUpdate> get caseUpdates;

  /// Idempotent — disconnects an existing session first. The access
  /// token is read fresh on every connect AND reconnect, so a rotated
  /// token is picked up automatically.
  Future<void> connect();

  Future<void> disconnect();
}
