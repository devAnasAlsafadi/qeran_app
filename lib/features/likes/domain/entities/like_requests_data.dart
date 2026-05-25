import 'package:equatable/equatable.dart';

import 'like_request_card.dart';

/// Top-level payload for `/api/likes/incoming` and `/api/likes/outgoing`.
///
/// The two lists are kept separate at the domain level so the UI can
/// render them differently — pending rows show the time chip + (for
/// incoming) the accept/reject buttons; archived rows render in a
/// muted "history" style.
///
/// [requiresSubscription] is the server-authoritative gate for the
/// **incoming** tab. When true, the rows in [pending] arrive with
/// `isLocked: true` and redacted identity — the UI shows the
/// subscription paywall above the list. Outgoing always reports
/// `false` here.
class LikeRequestsData extends Equatable {
  final List<LikeRequestCard> pending;
  final List<LikeRequestCard> archived;
  final bool requiresSubscription;

  const LikeRequestsData({
    required this.pending,
    required this.archived,
    required this.requiresSubscription,
  });

  bool get isEmpty => pending.isEmpty && archived.isEmpty;

  @override
  List<Object?> get props => [pending, archived, requiresSubscription];
}
