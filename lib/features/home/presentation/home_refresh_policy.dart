import 'dart:async';

import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';

/// When the user shell re-reads the server state that lives ABOVE any single
/// tab — the approval gate, the unread badges, the active subscription.
///
/// Three moments, three different answers. They live here rather than inline in
/// `HomeScreen` because "when do we refetch" is the thing that regresses
/// silently: the shell's lifecycle hooks cannot be exercised without Firebase,
/// DI and a live SignalR hub, so inline the policy is only ever verified by
/// hand on a device. Extracted, it is an ordinary unit under test.
///
/// Each method returns a future so a test can await it; every call site fires
/// it with `unawaited` — none of this is allowed to delay a frame.
class HomeRefreshPolicy {
  final ProfileGateCubit _profileGate;
  final BadgesCubit _badges;
  final CurrentSubscriptionCubit _subscription;

  const HomeRefreshPolicy({
    required ProfileGateCubit profileGate,
    required BadgesCubit badges,
    required CurrentSubscriptionCubit subscription,
  }) : _profileGate = profileGate,
       _badges = badges,
       _subscription = subscription;

  /// The shell mounted — a new shell means a new signed-in session.
  ///
  /// The gate is refreshed rather than reused so a previous account's resolved
  /// status cannot carry over; fetch failures stay fail-open, and the backend
  /// remains the real action gate. The badges are CLEARED before their refetch
  /// for the same reason — they are app-scoped and outlive the session that
  /// filled them, so the server's counts must replace the last account's, not
  /// merge with them.
  Future<void> onShellMount() {
    final gate = _profileGate.refresh();
    _badges.clear();
    return Future.wait([gate, _badges.refresh()]);
  }

  /// The app returned to the foreground.
  ///
  /// The gate is re-read here because nothing else re-reads it: it is fetched
  /// on shell mount, and the shell only mounts on a cold start. That is why an
  /// approval granted while the member watched needed a process kill to show up.
  ///
  /// UNCONDITIONAL, deliberately. Guarding on `isGated` would let an approval
  /// OPEN the gate and never let a later hide or rejection CLOSE it again —
  /// the same staleness bug pointing the other way.
  Future<void> onResume() => Future.wait([
    _profileGate.refresh(),
    _badges.refresh(),
    _subscription.refresh(force: true),
  ]);

  /// A push arrived while the app was already foregrounded. Refreshes the
  /// unread indicators; navigation is never automatic.
  Future<void> onForegroundPush() => _badges.refresh();
}
