class EndPoints {
  static const String baseUrl = "https://qeranadmin-001-site1.rtempurl.com/api/";

  /// Resolves a server-supplied relative path (e.g.
  /// `/api/users/profile-images/{id}`) to an absolute URL by joining it
  /// with the server origin. Passes through anything that already starts
  /// with `http://` or `https://`. Naive concatenation with [baseUrl]
  /// would double the `/api/` segment — this helper avoids that.
  static String absoluteUrl(String relativePath) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    final origin = Uri.parse(baseUrl).origin;
    return '$origin$relativePath';
  }

  // Auth
  static const String login = "Auth/login";
  static const String register = "Auth/register-new";
  static const String addPhone = "Auth/add-phone";
  static const String verifyOtp = "Auth/verify-otp";
  static const String forgotPassword = "Auth/forgot-password";
  static const String verifyForgotPasswordOtp =
      "Auth/verify-forgot-password-otp";
  static const String resetPassword = "Auth/reset-password";
  static const String firebaseSignIn = "Auth/firebase-signin";

  /// `POST /api/auth/change-password` — body
  /// `{oldPassword, newPassword, confirmNewPassword}`.
  /// Shared auth endpoint; consumed by the matchmaker account feature (S1c).
  static const String changePassword = "Auth/change-password";

  // Questionnaire
  static const String questions = "Questions";
  static const String submitAnswers = "Questions/submit";

  /// `GET /api/questions/edit-form` — the profile-edit schema: every
  /// active question for my gender, grouped by category, each carrying my
  /// current answer (`selectedOptionIds` / `textAnswer`). Written back via
  /// [submitAnswers], which replaces ALL answers (send every question).
  static const String editForm = "Questions/edit-form";

  // Profile
  static const String profileImages = "users/profile-images";

  /// `GET /api/profile` — my full profile. Returns the owner-shape
  /// `{userId, name, email, gender, birthDate, age, profileStatus,
  /// hasAnsweredQuestions, profileImage, images[isApproved], placements}`
  /// wrapped in `ApiResponse`.
  static const String myProfile = "profile";

  /// `DELETE /api/Profile` — permanent, non-recoverable account soft-delete
  /// (cancels any active subscription with no refund; chats/likes/archive
  /// disappear for everyone). Same resource as [myProfile]; aliased for a
  /// self-documenting call site.
  static const String deleteProfile = myProfile;

  /// `GET /api/discovery/profiles/{userId}` — another user's full
  /// profile (other-shape: id, name, age, matchingScore,
  /// images[isBlurred], placements). On failure backend returns
  /// `errorCode: "PROFILE_NOT_FOUND"`.
  static String profileById(String userId) =>
      "discovery/profiles/$userId";

  /// `GET /api/users/{id}` — lightweight user info (id, name, email,
  /// gender, age, latitude, longitude). No images, no placements. Use
  /// for cases where only a name/age is needed (e.g. comment/notif
  /// headers). NOT a substitute for [profileById].
  static String userBasic(String id) => "users/$id";

  // Devices / FCM
  static const String registerDevice = "Devices/register";
  static const String linkDevice = "Devices/link";

  /// `POST /Devices/unlink` — unlinks this device's FCM token (stop push),
  /// used best-effort during account deletion.
  /// ⚠️ Not yet in Swagger; body shape assumed `{token}` like link — confirm
  /// with backend (Tariq).
  static const String unlinkDevice = "Devices/unlink";

  // Discovery
  static const String discovery = "Discovery";
  static const String discoveryFilters = "Discovery/filters";

  /// `POST /api/likes/{targetUserId}` — Bearer JWT, no body. Backend
  /// uses the `{success, message, data}` envelope. On success, `data`
  /// is a string id ("42"). Known failure messages map to typed
  /// outcomes inside the Discovery data source.
  static String likeProfile(String targetUserId) => "likes/$targetUserId";

  /// `POST /api/discovery/skip/{targetUserId}` — permanent server-side
  /// skip. No subscription gate, no limit, no notification.
  static String discoverySkip(String targetUserId) =>
      "discovery/skip/$targetUserId";

  /// `GET /api/likes/incoming` — people who liked me. Subscription-gated:
  /// non-subscribers receive redacted rows with `isLocked: true`.
  static const String likesIncoming = "likes/incoming";

  /// `GET /api/likes/outgoing` — people I liked. Identity always
  /// visible.
  static const String likesOutgoing = "likes/outgoing";

  /// `POST /api/likes/{likeRequestId}/accept` — Bearer JWT, no body.
  /// Subscription-gated: returns the "الاشتراك مطلوب" message when the
  /// caller is not subscribed. Backend success moves the row from
  /// Pending → Accepted and pushes a notification to the sender.
  /// Photos remain blurred until the future photo-exchange API runs.
  static String likesAccept(int likeRequestId) =>
      "likes/$likeRequestId/accept";

  /// `POST /api/likes/{likeRequestId}/reject` — Bearer JWT, no body.
  /// No subscription gate, no push notification to the other user.
  /// Pending → Rejected; the row shows up in the archived list after
  /// the next refresh.
  static String likesReject(int likeRequestId) =>
      "likes/$likeRequestId/reject";

  /// `GET /api/matches` — Bearer JWT. Active matches (post-like-
  /// acceptance) regardless of stage 0/1/2. Archived matches live at
  /// `/api/matches/archived` and are not part of this feature yet.
  static const String matches = "matches";

  /// `POST /api/photo-exchange/request/{likeRequestId}` — initiator
  /// side. Subscription-gated.
  static String photoExchangeRequest(int likeRequestId) =>
      "photo-exchange/request/$likeRequestId";

  /// `POST /api/photo-exchange/{requestId}/accept` — responder side.
  /// `requestId` is `pendingPhotoExchange.id`, NOT the like id.
  static String photoExchangeAccept(int requestId) =>
      "photo-exchange/$requestId/accept";

  /// `POST /api/photo-exchange/{requestId}/reject` — responder side.
  /// Routes the relationship to the matchmaker (stage 2); does NOT
  /// archive.
  static String photoExchangeReject(int requestId) =>
      "photo-exchange/$requestId/reject";

  // Subscriptions
  static const String subscriptionPlans = "subscriptions/plans";
  static const String currentSubscription = "subscriptions/current";
  static const String subscribe = "subscriptions/subscribe";

  /// `POST /api/subscriptions/validate-code` — **raw** (no envelope). Body
  /// `{ code, productId, platform }`; returns the offer id + (iOS) StoreKit
  /// promotional-offer signature. See PAYWALL_IMPLEMENTATION_PLAN §2.4/§2.5.
  static const String validateCode = "subscriptions/validate-code";

  // Chat (User ↔ Matchmaker only)

  /// `GET /api/chat/my-matchmaker` — fast bootstrap path. Returns the
  /// assigned matchmaker info + the user's single conversation id, or
  /// status==0 with `لم يتم تعيين خطّابة لك بعد` if none yet.
  static const String chatMyMatchmaker = "chat/my-matchmaker";

  /// `GET /api/chat/conversations` — kept for forward compatibility
  /// (admin / multi-matchmaker futures). Not consumed by the MVP UI.
  static const String chatConversations = "chat/conversations";

  /// `GET /api/chat/conversations/{id}/messages?page=N&pageSize=M` —
  /// newest-first paged list of `ChatMessageDto`.
  static String chatMessages(int conversationId) =>
      "chat/conversations/$conversationId/messages";

  /// `POST /api/chat/conversations/{id}/messages` — body `{content}`.
  /// 60/min rate-limit; content 1..2000 chars; whitespace rejected.
  static String chatSendMessage(int conversationId) =>
      "chat/conversations/$conversationId/messages";

  /// `POST /api/chat/conversations/{id}/share-profile` — body
  /// `{sharedUserId}`. 20/5min rate-limit.
  static String chatShareProfile(int conversationId) =>
      "chat/conversations/$conversationId/share-profile";

  /// `POST /api/chat/conversations/{id}/read` — flips every inbound
  /// unread to read; fires the SignalR `MessagesRead` event to the
  /// other side. We never call this for our own messages.
  static String chatMarkAsRead(int conversationId) =>
      "chat/conversations/$conversationId/read";

  /// Absolute SignalR hub URL. Backend confirmed the hub is mounted
  /// at `/hubs/chat` on the SAME host as the REST API, with NO
  /// `/api` prefix. We derive the origin from [baseUrl] so any host
  /// change in one place lands everywhere.
  static String get chatHubUrl =>
      '${Uri.parse(baseUrl).origin}/hubs/chat';

  // ─── Matchmaker (role=Moderator) ─────────────────────
  // Source: docs/MOBILE_MATCHMAKER_FLOW.md.
  // String constants only — no behavior, no validation.

  /// `GET /api/matchmaker/dashboard` — 6 counters
  /// (pending users, approved sub/unsub, active compat cases,
  /// unread messages, total assigned).
  static const String matchmakerDashboard = "matchmaker/dashboard";

  /// `GET /api/matchmaker/users/pending?page=N&pageSize=M`
  static const String matchmakerUsersPending = "matchmaker/users/pending";

  /// `GET /api/matchmaker/users/approved-unsubscribed?page=N&pageSize=M`
  static const String matchmakerUsersApprovedUnsubscribed =
      "matchmaker/users/approved-unsubscribed";

  /// `GET /api/matchmaker/users/approved-subscribed?page=N&pageSize=M&planId=P`
  /// (`planId` optional — filters subscribers to that plan, server-side).
  static const String matchmakerUsersApprovedSubscribed =
      "matchmaker/users/approved-subscribed";

  /// `GET /api/matchmaker/users/subscription-plans` — the dynamic plan list
  /// (planId/nameAr/nameEn/subscriberCount) backing the plan-filter rail.
  static const String matchmakerUsersSubscriptionPlans =
      "matchmaker/users/subscription-plans";

  /// `GET /api/matchmaker/users/{id}/profile` — full profile (never blurred).
  static String matchmakerUserProfile(String userId) =>
      "matchmaker/users/$userId/profile";

  /// `POST /api/matchmaker/users/{id}/approve` — body empty.
  static String matchmakerUserApprove(String userId) =>
      "matchmaker/users/$userId/approve";

  /// `POST /api/matchmaker/users/{id}/reject` — body `{reason}` (≤500 chars).
  static String matchmakerUserReject(String userId) =>
      "matchmaker/users/$userId/reject";

  /// `POST /api/matchmaker/users/{id}/request-image` — body empty.
  static String matchmakerUserRequestImage(String userId) =>
      "matchmaker/users/$userId/request-image";

  /// `POST /api/matchmaker/users/{id}/text-answer` — body `{questionId, textAnswer}`.
  static String matchmakerUserTextAnswer(String userId) =>
      "matchmaker/users/$userId/text-answer";

  /// `GET /api/matchmaker/users/{id}/chat` — lazy-open conversation.
  /// Returns `conversationId`.
  static String matchmakerUserChat(String userId) =>
      "matchmaker/users/$userId/chat";

  /// `GET|PUT|DELETE /api/matchmaker/users/{id}/note` — assigned-users only.
  /// GET → note or `data:null`; PUT body `{content}` (≤2000, trimmed) upserts;
  /// DELETE is idempotent.
  static String matchmakerUserNote(String userId) =>
      "matchmaker/users/$userId/note";

  /// `GET /api/matchmaker/users/{id}/likes/outgoing` — likes this user sent.
  static String matchmakerUserLikesOutgoing(String userId) =>
      "matchmaker/users/$userId/likes/outgoing";

  /// `GET /api/matchmaker/users/{id}/likes/incoming` — likes this user got.
  static String matchmakerUserLikesIncoming(String userId) =>
      "matchmaker/users/$userId/likes/incoming";

  /// `GET /api/matchmaker/users/{id}/matches` — this user's active matches.
  static String matchmakerUserMatches(String userId) =>
      "matchmaker/users/$userId/matches";

  /// `GET /api/matchmaker/users/{id}/matches/archived` — closed/cancelled.
  static String matchmakerUserMatchesArchived(String userId) =>
      "matchmaker/users/$userId/matches/archived";

  /// `GET /api/matchmaker/compatibility-cases?page=N&pageSize=M`
  static const String matchmakerCompatibilityCases =
      "matchmaker/compatibility-cases";

  /// `POST /api/matchmaker/compatibility-cases/{formalRequestId}/status`
  /// — body `{newStatus}` (1..5).
  static String matchmakerCompatibilityCaseStatus(int formalRequestId) =>
      "matchmaker/compatibility-cases/$formalRequestId/status";

  /// `GET|PUT|DELETE /api/matchmaker/compatibility-cases/{caseId}/my-note`
  /// — the matchmaker's OWN private per-case note (strictly per-matchmaker).
  /// GET → note or `data:null`; PUT body `{content}` (≤2000, trimmed) upserts;
  /// DELETE is idempotent.
  static String matchmakerCompatibilityCaseNote(int caseId) =>
      "matchmaker/compatibility-cases/$caseId/my-note";

  /// `GET /api/matchmaker/explore?page=N&pageSize=M&search=...&gender=...`
  static const String matchmakerExplore = "matchmaker/explore";

  /// `GET /api/matchmaker/explore/filters` — available filter questions.
  static const String matchmakerExploreFilters = "matchmaker/explore/filters";

  /// `GET /api/matchmaker/colleagues?page=N&pageSize=M`
  static const String matchmakerColleagues = "matchmaker/colleagues";

  /// `POST /api/matchmaker/colleagues/{id}/open-chat` — body empty.
  /// Returns `conversationId`.
  static String matchmakerColleagueOpenChat(String colleagueId) =>
      "matchmaker/colleagues/$colleagueId/open-chat";

  /// `GET /api/matchmaker/conversations/users?page=N&pageSize=M`
  static const String matchmakerConversationsUsers =
      "matchmaker/conversations/users";

  /// `GET /api/matchmaker/conversations/colleagues?page=N&pageSize=M`
  static const String matchmakerConversationsColleagues =
      "matchmaker/conversations/colleagues";

  /// `GET /api/matchmaker/me` — current matchmaker profile.
  static const String matchmakerMe = "matchmaker/me";

  /// `PUT /api/matchmaker/me` — body `{name}`.
  static const String matchmakerMeUpdate = "matchmaker/me";

  /// `POST /api/matchmaker/me/profile-photo` — multipart, jpg/jpeg/png ≤2MB.
  static const String matchmakerMeProfilePhoto = "matchmaker/me/profile-photo";

  /// `POST /api/matchmaker/me/deactivate` — body empty.
  static const String matchmakerMeDeactivate = "matchmaker/me/deactivate";

  /// `GET /api/affiliate/summary` — the matchmaker's referral/commission
  /// totals (code, referred/registered/used counts, earnings by state).
  /// Read via `getRaw` so a 404 (matchmaker not enrolled in the program)
  /// surfaces its transport status for the not-enrolled state.
  static const String affiliateSummary = "affiliate/summary";

  /// `GET /api/affiliate/commissions?page=N&pageSize=M` — the matchmaker's
  /// commission ledger, paginated `{ items, page, pageSize, totalCount }`.
  /// Read via `getRaw` (tolerant of a bare vs enveloped payload).
  static const String affiliateCommissions = "affiliate/commissions";

  /// `GET /api/notifications?page=N&pageSize=M` — shared inbox (not
  /// matchmaker-namespaced). Items carry no read-state; the unread badge is a
  /// local heuristic (see the matchmaker notifications feature).
  static const String notifications = "notifications";

  /// `GET /api/notifications/count` — `{ count }` (total, not unread).
  static const String notificationsCount = "notifications/count";

  // Legal documents — public (no JWT), bilingual sectioned content.
  /// `GET /api/privacy-policy` — `{ lastUpdatedAt, sections[] }`.
  static const String privacyPolicy = "privacy-policy";

  /// `GET /api/terms-and-conditions` — same shape as [privacyPolicy].
  static const String termsAndConditions = "terms-and-conditions";

  // Support / Help (JWT-gated). Not in the published Swagger yet — verified
  // live (404 for unknown sub-paths vs 401 here confirms the routes exist).
  /// `GET /api/support/categories` — problem-type list
  /// (`[{id, nameAr, nameEn, icon}]`) backing the form dropdown.
  static const String supportCategories = "support/categories";

  /// `POST /api/support/tickets` — body `{categoryId, subject(≤200),
  /// details(≤4000)}`. Failure envelope carries `errorCode`
  /// (`SUPPORT_TICKETS_LIMIT_REACHED` past 5 open tickets,
  /// `SUPPORT_CATEGORY_NOT_FOUND`, `VALIDATION_ERROR`).
  static const String supportTickets = "support/tickets";
}
