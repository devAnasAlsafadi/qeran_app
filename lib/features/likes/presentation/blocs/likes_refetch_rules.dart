import 'likes_state.dart';

/// Whether an action's result means the list it acted on has to be refetched.
///
/// All six encode ONE rule, in three parts:
///
///   1. Refetch when the server's answer proves the card acted on a STALE
///      view — the request was already pending, the like was never accepted,
///      the formal step is not allowed at this stage, the case has ended, the
///      thing being answered is gone or expired. In every one of those the
///      screen is showing something that is not true any more, and only a
///      refetch fixes it.
///
///   2. Do NOT refetch when the answer is a gate on the ACTOR rather than a
///      statement about the card: needs a subscription, monthly limit reached,
///      profile still under review. The row is exactly as the screen drew it;
///      the member simply may not act on it yet. Refetching would cost a round
///      trip to redraw the same thing.
///
///   3. Never refetch on a transport failure, where the server said nothing
///      at all. There is no new truth to fetch, and the request that just
///      failed is poor evidence the next one will not.
///
/// Read together rather than scattered through the cubit, which is the point
/// of this file: the difference between «لا يمكن بدء الخطوة الرسمية في
/// هذه المرحلة» (part 1, refetch) and «ملفك قيد المراجعة» (part 2, do not)
/// is invisible when the two live four hundred lines apart.

bool refetchIncomingAfterLikeAction(LikesActionEvent event) {
  return switch (event) {
    LikesActionEvent.acceptSuccess ||
    LikesActionEvent.acceptExpired ||
    LikesActionEvent.acceptNotFound ||
    LikesActionEvent.rejectSuccess ||
    LikesActionEvent.rejectExpired ||
    LikesActionEvent.rejectNotFound => true,
    _ => false,
  };
}

bool refetchMatchesAfterPhotoRequest(LikesActionEvent event) {
  return switch (event) {
    LikesActionEvent.photoExchangeRequestSuccess ||
    LikesActionEvent.photoExchangeRequestAlreadyPending ||
    LikesActionEvent.photoExchangeRequestLikeNotAccepted => true,
    _ => false,
  };
}

bool refetchMatchesAfterPhotoRespond(LikesActionEvent event) {
  return switch (event) {
    LikesActionEvent.photoExchangeAcceptSuccess ||
    LikesActionEvent.photoExchangeRejectSuccess ||
    LikesActionEvent.photoExchangeRespondNotFound ||
    LikesActionEvent.photoExchangeRespondExpired => true,
    _ => false,
  };
}

/// Refetch whenever the server's view of the case turned out to differ from
/// the one this screen acted on — including the refusals that describe the
/// CASE: already pending, not allowed at this stage, already ended.
///
/// Not `formalStepUnderReview`, which describes the MEMBER and leaves the card
/// exactly as drawn. This doc used to say "every one of the refusals", which
/// was never what the code did — visible now that the six rules sit together.
bool refetchMatchesAfterFormalRequest(LikesActionEvent event) {
  return switch (event) {
    LikesActionEvent.formalStepSuccess ||
    LikesActionEvent.formalStepAlreadyPending ||
    LikesActionEvent.formalStepNotAllowed ||
    LikesActionEvent.formalStepCaseEnded => true,
    _ => false,
  };
}

/// Every answer the SERVER gave moves the case or proves the card stale, so
/// all four refetch. Only a transport failure — where the server said
/// nothing at all — leaves the list alone.
bool refetchMatchesAfterFormalRespond(LikesActionEvent event) {
  return switch (event) {
    LikesActionEvent.formalStepAcceptSuccess ||
    LikesActionEvent.formalStepRejectSuccess ||
    LikesActionEvent.formalStepRespondNotFound ||
    LikesActionEvent.formalStepRespondExpired ||
    LikesActionEvent.formalStepRespondCaseEnded => true,
    _ => false,
  };
}

/// Success refetches because the row does NOT disappear — the case stays in
/// `/api/matches` and comes back reading as ended, which is the only way the
/// card learns it. The other two are the server saying the card was already
/// stale, so they refetch for the same reason. Only a transport failure,
/// where the server said nothing at all, leaves the list alone.
bool refetchMatchesAfterCancel(LikesActionEvent event) {
  return switch (event) {
    LikesActionEvent.cancelSuccess ||
    LikesActionEvent.cancelAlreadyEnded ||
    LikesActionEvent.cancelNotFound => true,
    _ => false,
  };
}
