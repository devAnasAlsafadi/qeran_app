import 'package:equatable/equatable.dart';

import 'subscription_plan.dart';
import 'subscription_pricing.dart';

/// The currently active (or most-recent) subscription for the authenticated
/// user. `null` from `/api/subscriptions/current` means "never subscribed
/// or already cleaned up" — handled at the repository layer as
/// `Right(null)`, not as a failure.
///
/// **Active-rule:** [isCurrentlyActive] (`expiresAt > now`) is the only
/// thing the app should consult to gate features. The server's
/// [isActive] flag is informational — never read it for gating.
class CurrentSubscription extends Equatable {
  /// Sentinel returned by the backend for "unlimited" on **remaining**
  /// counters (`int.MaxValue`, distinct from the features payload's `-1`).
  static const int unlimitedRemainingSentinel = 2147483647;

  final int id;
  final SubscriptionPlan plan;
  final SubscriptionPricing pricing;

  final DateTime startsAt;
  final DateTime expiresAt;

  /// Server-side flag. **Do not** gate features on this — use
  /// [isCurrentlyActive] instead.
  final bool isActive;

  final int likesUsed;
  final int likesRemaining;
  final int seriousInterestsUsed;
  final int seriousInterestsRemaining;
  final int photoExchangesUsed;
  final int photoExchangesRemaining;

  const CurrentSubscription({
    required this.id,
    required this.plan,
    required this.pricing,
    required this.startsAt,
    required this.expiresAt,
    required this.isActive,
    required this.likesUsed,
    required this.likesRemaining,
    required this.seriousInterestsUsed,
    required this.seriousInterestsRemaining,
    required this.photoExchangesUsed,
    required this.photoExchangesRemaining,
  });

  /// True when [value] is the "unlimited" sentinel on a remaining counter.
  static bool isUnlimitedRemaining(int value) =>
      value == unlimitedRemainingSentinel;

  /// SOT for "subscription currently active". `expiresAt > now` —
  /// `isActive` is intentionally ignored.
  bool get isCurrentlyActive => DateTime.now().isBefore(expiresAt);

  /// Days remaining before [expiresAt]. Negative for already-expired.
  int get daysRemaining =>
      expiresAt.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [
        id,
        plan,
        pricing,
        startsAt,
        expiresAt,
        isActive,
        likesUsed,
        likesRemaining,
        seriousInterestsUsed,
        seriousInterestsRemaining,
        photoExchangesUsed,
        photoExchangesRemaining,
      ];
}
