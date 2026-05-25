import 'package:equatable/equatable.dart';

import '../../../domain/entities/current_subscription.dart';

sealed class CurrentSubscriptionState extends Equatable {
  const CurrentSubscriptionState();

  @override
  List<Object?> get props => const [];
}

final class CurrentSubscriptionInitial extends CurrentSubscriptionState {
  const CurrentSubscriptionInitial();
}

final class CurrentSubscriptionLoading extends CurrentSubscriptionState {
  const CurrentSubscriptionLoading();
}

/// The user has an active subscription (`expiresAt > now` is the SOT —
/// callers check `subscription.isCurrentlyActive`).
final class CurrentSubscriptionLoaded extends CurrentSubscriptionState {
  final CurrentSubscription subscription;
  const CurrentSubscriptionLoaded(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

/// The user has no subscription on record (server returned `null`).
final class CurrentSubscriptionNone extends CurrentSubscriptionState {
  const CurrentSubscriptionNone();
}

/// Transport / parsing error. The cubit keeps the previous state's
/// payload in `lastKnown` so UI can decide whether to retry or fall
/// back to stale data.
final class CurrentSubscriptionFailure extends CurrentSubscriptionState {
  final String message;
  final CurrentSubscription? lastKnown;
  const CurrentSubscriptionFailure({
    required this.message,
    this.lastKnown,
  });

  @override
  List<Object?> get props => [message, lastKnown];
}
