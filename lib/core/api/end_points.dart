class EndPoints {
  static const String baseUrl = "http://tatates-001-site1.qtempurl.com/api/";

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

  // Questionnaire
  static const String questions = "Questions";
  static const String submitAnswers = "Questions/submit";

  // Profile
  static const String profileImages = "users/profile-images";

  /// `GET /api/profile` — my full profile. Returns the owner-shape
  /// `{userId, name, email, gender, birthDate, age, profileStatus,
  /// hasAnsweredQuestions, profileImage, images[isApproved], placements}`
  /// wrapped in `ApiResponse`.
  static const String myProfile = "profile";

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
  static String validateDiscountCode(String code) =>
      "subscriptions/discount-codes/$code/validate";

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
}
