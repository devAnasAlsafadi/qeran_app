import 'package:equatable/equatable.dart';

import 'matchmaker_interest_like.dart';

/// A likes-tab payload (ActivityPageDto): [pending] + [archived] rows plus the
/// [requiresSubscription] gate (true only on the incoming tab when the viewed
/// user isn't subscribed — drives a neutral notice, never a buy CTA).
class MatchmakerLikeActivity extends Equatable {
  final List<MatchmakerInterestLike> pending;
  final List<MatchmakerInterestLike> archived;
  final bool requiresSubscription;

  const MatchmakerLikeActivity({
    this.pending = const [],
    this.archived = const [],
    this.requiresSubscription = false,
  });

  bool get isEmpty => pending.isEmpty && archived.isEmpty;

  @override
  List<Object?> get props => [pending, archived, requiresSubscription];
}
