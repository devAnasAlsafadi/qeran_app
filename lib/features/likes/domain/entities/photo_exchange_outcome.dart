// Typed outcomes for photo-exchange domain calls.
//
// Like `LikeActionOutcome`, these live on the `Right` of an `Either`;
// transport / unknown failures stay on the `Left` as `Failure`. Raw
// server messages are kept only for logging — the UI uses localized
// keys.

/// Outcome of `POST /api/photo-exchange/request/{likeRequestId}`.
sealed class PhotoExchangeRequestOutcome {
  const PhotoExchangeRequestOutcome();
}

/// Backend recorded the request. `requestId` is the new
/// `pendingPhotoExchange.id` (returned as a string in `data`, parsed
/// into int when possible).
final class PhotoExchangeRequestSuccess extends PhotoExchangeRequestOutcome {
  final int? requestId;
  final String serverMessage;
  const PhotoExchangeRequestSuccess({
    required this.requestId,
    required this.serverMessage,
  });
}

/// `LIKE_NOT_ACCEPTED` — the row isn't ready for photo exchange
/// (either still pending or the like was rejected/expired).
final class PhotoExchangeRequestLikeNotAccepted
    extends PhotoExchangeRequestOutcome {
  final String serverMessage;
  const PhotoExchangeRequestLikeNotAccepted({required this.serverMessage});
}

/// `PHOTO_EXCHANGE_ALREADY_PENDING` — a pending request already
/// exists. The UI refreshes matches so the existing one surfaces.
final class PhotoExchangeRequestAlreadyPending
    extends PhotoExchangeRequestOutcome {
  final String serverMessage;
  const PhotoExchangeRequestAlreadyPending({required this.serverMessage});
}

/// `SUBSCRIPTION_REQUIRED` — caller has no active subscription. UI
/// opens the existing paywall sheet with `PaywallIntent.photoExchange`.
final class PhotoExchangeRequestRequiresSubscription
    extends PhotoExchangeRequestOutcome {
  final String serverMessage;
  const PhotoExchangeRequestRequiresSubscription({required this.serverMessage});
}

/// `VALIDATION_ERROR` / other unmapped status-0 envelopes.
final class PhotoExchangeRequestFailure extends PhotoExchangeRequestOutcome {
  final String serverMessage;
  final String? errorCode;
  const PhotoExchangeRequestFailure({
    required this.serverMessage,
    required this.errorCode,
  });
}

/// Outcome of `POST /api/photo-exchange/{requestId}/accept` and
/// `POST /api/photo-exchange/{requestId}/reject` — shared shape since
/// the failure surface is identical.
sealed class PhotoExchangeRespondOutcome {
  const PhotoExchangeRespondOutcome();
}

final class PhotoExchangeRespondSuccess extends PhotoExchangeRespondOutcome {
  final String serverMessage;
  const PhotoExchangeRespondSuccess({required this.serverMessage});
}

/// `PHOTO_EXCHANGE_NOT_FOUND` — the request id no longer exists.
final class PhotoExchangeRespondNotFound extends PhotoExchangeRespondOutcome {
  final String serverMessage;
  const PhotoExchangeRespondNotFound({required this.serverMessage});
}

/// `PHOTO_EXCHANGE_EXPIRED` — pending TTL elapsed.
final class PhotoExchangeRespondExpired extends PhotoExchangeRespondOutcome {
  final String serverMessage;
  const PhotoExchangeRespondExpired({required this.serverMessage});
}

final class PhotoExchangeRespondFailure extends PhotoExchangeRespondOutcome {
  final String serverMessage;
  final String? errorCode;
  const PhotoExchangeRespondFailure({
    required this.serverMessage,
    required this.errorCode,
  });
}
