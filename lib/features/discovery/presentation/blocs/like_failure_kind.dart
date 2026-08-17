/// Typed projection of the last failed Like attempt.
///
/// The cubit stores this on the loaded state so the UI listener can
/// dispatch the right surface — paywall sheet vs transient toast vs
/// generic error — without re-classifying the raw server message at
/// the widget level. `null` means no current failure (the action either
/// succeeded or none has been attempted since the last clear).
enum LikeFailureKind {
  /// Subscription required or like quota exhausted.
  paywall,

  /// `يوجد طلب قائم بالفعل بينكما` — like already exists between the
  /// two users.
  alreadyPending,

  /// `لا يمكن إرسال إعجاب لشخص من نفس الجنس` — backend's matchmaking
  /// rule rejected the like.
  genderMismatch,

  /// `المستخدم غير موجود أو غير مرئي` — target user was removed or
  /// hid their profile.
  userUnavailable,

  /// `PROFILE_NOT_APPROVED` — the caller's OWN profile is still under
  /// matchmaker review, so liking is gated. UI keeps the card in place and
  /// shows a localized "under review" toast (never a paywall).
  underReview,

  /// Transport-level failure (timeout, parse) OR an unrecognised server
  /// message. UI shows a generic error toast.
  network,

  /// Device reported no connectivity (`OfflineFailure`). UI shows the
  /// dedicated offline toast instead of the generic one.
  offline,
}
