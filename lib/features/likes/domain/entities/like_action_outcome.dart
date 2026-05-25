/// Sealed result of an Accept / Reject attempt on an incoming like.
///
/// Returned on the `Right` side of `Either<Failure, LikeActionOutcome>` —
/// these are semantic backend outcomes the cubit branches on. Transport-
/// level errors (network / timeout / parse) stay on the `Left` side as
/// `Failure` and surface as the localized generic error.
sealed class LikeActionOutcome {
  const LikeActionOutcome();
}

/// Backend reported `status == 1`. For accept the row flips to
/// Accepted and a push notification fires to the sender; photos stay
/// blurred until the future photo-exchange endpoint runs. For reject
/// the row moves to archived (Rejected). The cubit refreshes the
/// incoming list either way.
final class LikeActionSuccess extends LikeActionOutcome {
  final String serverMessage;
  const LikeActionSuccess({required this.serverMessage});
}

/// Caller has no active subscription — accept is gated.
/// `"الاشتراك مطلوب لقبول الإعجابات"`. UI opens the existing paywall
/// sheet with `PaywallIntent.acceptLike`.
final class LikeActionRequiresSubscription extends LikeActionOutcome {
  final String serverMessage;
  const LikeActionRequiresSubscription({required this.serverMessage});
}

/// Request id is invalid or no longer pending — the row was archived
/// or rejected concurrently. `"الطلب غير موجود أو منتهي"` /
/// `"الطلب غير موجود"`. UI shows a localized message and refreshes.
final class LikeActionNotFoundOrExpired extends LikeActionOutcome {
  final String serverMessage;
  const LikeActionNotFoundOrExpired({required this.serverMessage});
}

/// Pending TTL elapsed server-side. `"انتهت مدة الطلب"`. Distinct from
/// "not found" so the UI can show "request expired" copy.
final class LikeActionExpired extends LikeActionOutcome {
  final String serverMessage;
  const LikeActionExpired({required this.serverMessage});
}

/// Backend returned `status == 0` with an unrecognised message. The
/// raw text is logged but never shown directly — the UI surfaces a
/// localized generic error.
final class LikeActionFailure extends LikeActionOutcome {
  final String serverMessage;
  const LikeActionFailure({required this.serverMessage});
}
