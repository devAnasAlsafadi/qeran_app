# Caching & Data-Fetching Investigation (Read-Only Diagnosis)

> **Scope:** Read-only audit of the app's data-fetching, caching, realtime, and offline behavior across **both roles** (regular user + matchmaker/"Moderator"). **No source file was modified.** This is diagnosis only — it deliberately proposes **no** implementation strategy. It is the foundation for a later planning step.
>
> **Method:** Verified from code (not from `HANDOFF.md` or commit messages). Network layer + endpoint catalog read from primary source; per-feature triggers gathered by four parallel read-only sweeps and cross-checked. Every claim below carries a `file:line` or exact endpoint string.
>
> **Reproduced base facts:**
> - API base URL: `https://qeranadmin-001-site1.rtempurl.com/api/` ([end_points.dart:2](../lib/core/api/end_points.dart#L2))
> - SignalR hub: `{origin}/hubs/chat` ([end_points.dart:182-183](../lib/core/api/end_points.dart#L182))

---

## Executive summary (headline findings)

1. **There is no data cache.** The app has **no local database** (no Hive/sqflite/isar/objectbox in [pubspec.yaml](../pubspec.yaml)) and **no HTTP cache layer** ([http_consumer.dart](../lib/core/api/http_consumer.dart) respects no `Cache-Control`/`ETag`). The only persistence is auth/session/onboarding flags in secure storage + `SharedPreferences`, and the OS-default image cache from `cached_network_image`. **Every list and profile is a network round-trip.**

2. **No offline detection at all.** `connectivity_plus` is **not a dependency**. `OfflineFailure` is *defined* ([errors.dart:38-40](../lib/core/errors/errors.dart#L38)) but **never thrown anywhere**. Offline = a 30-second hang, then a generic error + retry. No offline banner.

3. **The "re-fetch on every navigation" complaint is partly fixed, partly real.** Both shells now use `IndexedStack`, so **tab switches and push/pop no longer re-fetch** — list/pagination state survives within a session. The re-fetch the user perceives is now concentrated at: (a) **cold start / re-login** (everything reloads), and (b) several **per-open screens** (paywall plans, profile-edit form, every detail sheet) that have no cache.

4. **Concrete waste exists** and is itemized in §8 — most notably: the **notification badge + inbox both hit the notifications endpoint separately** (and the matchmaker badge can fire `/count` twice in a row), **subscription plans re-fetch on every paywall open**, the **profile-edit schema re-fetches every visit**, and **entering either home shell fans out 4–5 parallel GETs at once** because `IndexedStack` mounts every tab's cubit eagerly.

5. **No token-refresh / 401 handling.** A 401 surfaces as a generic error string ([http_consumer.dart:385-394](../lib/core/api/http_consumer.dart#L385)); there is no refresh interceptor and no forced re-login flow.

---

## 1. Current caching state

### 1.1 Local database — **NONE**
No `Hive`, `sqflite`, `isar`, or `objectbox` in [pubspec.yaml](../pubspec.yaml). Persistence dependencies are only `shared_preferences`, `flutter_secure_storage`, and `cached_network_image`.

### 1.2 Secure storage — **auth token only (as designed)**
[secure_storage_service.dart](../lib/core/datasources/secure_storage_service.dart) wraps `FlutterSecureStorage`.
- Stores **only** `StorageKeys.token` (JWT). Read on **every** HTTP request at [http_consumer.dart:30](../lib/core/api/http_consumer.dart#L30) and attached as `Authorization: Bearer …`.
- Cleared on sign-out and on account delete (`_secureStorage.clear()`).
- **No non-auth data is stored here** — clean. No flag needed.

### 1.3 SharedPreferences — **session/onboarding flags, NOT a data cache**
[shared_pref_service.dart](../lib/core/datasources/shared_pref_service.dart), keys in [storage_keys.dart](../lib/core/constants/storage_keys.dart). Disk-backed, **no TTL, no invalidation**. Used by `UserSessionCubit.hydrate()` and the splash router:
- **Identity/session:** `userId`, `userName`, `userEmail`, `userRole` (role drives the splash branch), `firebaseUid`.
- **Onboarding gates:** `isWhatsappVerified`, `finishedQuestions`, `gender`, `signedOath`, `questionnaireDraft`, `uploadedPhotos`.
- **FCM/device markers** (preserved across account delete): `latestFcmToken`, `deviceRegistered`, `lastRegisteredFcm`, `lastRegisteredLang`, `lastLinkedFcm`, `notifPermissionAsked`.
- **Notification read-state heuristics:** `notifLastSeenId` (user) and `matchmakerNotifLastSeenCount` (matchmaker). These are the **only** "domain data" in prefs, and they are tiny counters/ids — not cached payloads.

> **Takeaway:** prefs hold *flags*, never *list/profile payloads*. There is no persisted cache of any feed, list, or profile.

### 1.4 Image cache — `cached_network_image` (OS-default)
Three JWT-headered call sites, all using the default memory+disk cache (no custom config, no TTL, no cache-busting):
- [like_blurred_image.dart:78](../lib/features/likes/presentation/widgets/like_blurred_image.dart#L78) — received-likes / matches imagery.
- [discovery_blurred_image.dart:39](../lib/features/discovery/presentation/widgets/discovery_blurred_image.dart#L39) — discovery card background.
- [matchmaker_user_avatar.dart:52](../lib/features/matchmaker/shared/presentation/widgets/matchmaker_user_avatar.dart#L52) — matchmaker avatars (never blurred).

This is the **only thing that survives offline today** (a previously-seen image renders), but the surrounding metadata does not.

### 1.5 In-memory caches — **cubit-scoped only**
No singleton static caches, no global catalogs, no cache layer in repositories/data sources. `BaseRepository.executeApiCall<T>()` ([base_repository.dart](../lib/core/repositories/base_repository.dart)) is a pure `Either` wrapper — no caching. Every `fetchPage()` / `getX()` hits the network.

The only in-memory "caches" live inside cubits and die with them:
| Cubit field | File | What it holds | Lifetime |
|---|---|---|---|
| `LikesCubit` per-tab slots | [likes_cubit.dart](../lib/features/likes/presentation/blocs/likes_cubit.dart) | Lazy-loaded tab results, kept until pull-to-refresh; matches slot invalidated after accept-like | Cubit lifetime |
| `QuestionnaireCubit._questions` | [questionnaire_remote_datasource.dart](../lib/features/questionnaire/data/datasources/questionnaire_remote_datasource.dart) caller | Intake question catalog after first fetch | Cubit lifetime |
| `LegalDocumentCubit._cache` (map) | legal cubit | Terms/Privacy per `LegalDocumentType` — tab toggle is instant after first fetch | Cubit lifetime |
| `SupportCubit` state | support cubit | Categories list | Cubit lifetime |
| `CurrentSubscriptionCubit` | [current_subscription_cubit.dart](../lib/features/subscriptions/presentation/blocs/current_subscription_cubit.dart) | Current subscription, **60s TTL** + in-flight coalescing — the one real TTL cache in the app | App-wide (lazySingleton) |
| `MatchmakerInterestsCubit` per-tab | matchmaker interests cubit | Likes/matches tabs lazy-loaded, cached in parent state | Cubit lifetime |

> The only **app-wide** in-memory caches are `CurrentSubscriptionCubit` (60s TTL) and the two notification-badge singletons (no TTL).

---

## 2. Network layer

All from [http_consumer.dart](../lib/core/api/http_consumer.dart) / [api_consumer.dart](../lib/core/api/api_consumer.dart):

| Aspect | Finding | Evidence |
|---|---|---|
| Client | Single `http.Client`, manual `Uri` build per call | [http_consumer.dart:44-62](../lib/core/api/http_consumer.dart#L44) |
| Timeout | **30s** standard, **60s** multipart | [http_consumer.dart:20-21](../lib/core/api/http_consumer.dart#L20) |
| Retry / backoff | **NONE** — single-shot `.timeout()` then catch | every verb method |
| Caching interceptor | **NONE** — no `Cache-Control`/`ETag`/`If-Modified-Since` | whole file |
| Auth header | Token re-read from storage and attached **per request** | [http_consumer.dart:29-37](../lib/core/api/http_consumer.dart#L29) |
| `Accept-Language` | Attached per request from `LanguageService` | [http_consumer.dart:34](../lib/core/api/http_consumer.dart#L34) |
| 401 handling | Mapped to `errors_unauthorized` string; **no refresh, no re-login** | [http_consumer.dart:385-394](../lib/core/api/http_consumer.dart#L385) |
| Envelope | `_handleResponse` enforces `status==1`; `_handleRawResponse` allows raw arrays / `null` / `{success}` (subscriptions, likes) | [http_consumer.dart:252-378](../lib/core/api/http_consumer.dart#L252) |
| Error typing | `CodedServerException` carries optional `errorCode` for data-source classification | [http_consumer.dart:266-298](../lib/core/api/http_consumer.dart#L266) |

**Connectivity:** `connectivity_plus` (or any equivalent) is **absent from [pubspec.yaml](../pubspec.yaml)**. Nothing listens for connectivity. `OfflineFailure` ([errors.dart:38-40](../lib/core/errors/errors.dart#L38)) is **never thrown** — `BaseRepository` only catches `ServerException`/`AuthException`/generic, and a dead network just times out into `ServerFailure`. **No global offline banner / indicator widget exists.**

---

## 3. Realtime channels (SignalR)

**One hub, two independent connections** (full role isolation), both pointed at `{origin}/hubs/chat` with `withAutomaticReconnect()` and a token-factory that re-auths on connect **and** reconnect.

### 3.1 User-side — `ChatRealtimeSignalRService` ([chat_realtime_signalr_service.dart](../lib/features/chat/data/datasources/chat_realtime_signalr_service.dart))
- DI: `ChatRealtimePort` **lazySingleton** ([chat_injection.dart:30](../lib/features/chat/di/chat_injection.dart#L30)); wired/owned per-conversation by `ConversationCubit` (pause on background, resume + catch-up on foreground).

| Event | Payload | Handler → Cubit | Screen | Updates cache or re-fetches? |
|---|---|---|---|---|
| `ReceiveMessage` | full `ChatMessageDto` | `ConversationCubit._onIncomingMessage` | `ChatConversationScreen` | **Updates in-memory** message list (append, dedup by `serverId`) |
| `MessagesRead` | `{conversationId, readByUserId, readAt}` | `ConversationCubit._onMessagesRead` | `ChatConversationScreen` | **Updates in-memory** (flips `isRead`) |

- **Reconnect catch-up:** SignalR does not replay; `ConversationCubit` re-fetches **page 1** and merges by `serverId` to recover missed messages.
- **The user app has no other realtime.** Per [home_screen.dart:36-38](../lib/features/home/presentation/screens/home_screen.dart#L36), the user shell has "no SignalR" outside chat — the notification bell is refreshed by the **FCM foreground stream**, not a socket.

### 3.2 Matchmaker-side — `MatchmakerRealtimeSignalRService` ([matchmaker_realtime_signalr_service.dart](../lib/features/matchmaker/shared/data/datasources/matchmaker_realtime_signalr_service.dart))
- DI: `MatchmakerRealtimePort` **lazySingleton** ([matchmaker_injection.dart:367](../lib/features/matchmaker/di/matchmaker_injection.dart#L367)); owned by `MatchmakerHomeScreen` (kept alive on background; reconnects on resume if dropped).

| Event | Payload | Handler → Cubit | Screen | Updates cache or re-fetches? |
|---|---|---|---|---|
| `CompatibilityCaseUpdated` | `{caseId, formalRequestId, newStatus, newStatusCode, updatedAt}` | `MatchmakerCasesListCubit._onCaseUpdate` | Cases tab | **Updates in-memory** (in-place; removes on terminal status) |
| `ReceiveMessage` (user convos) | reduced `{conversationId, senderId, contentPreview, sentAt}` | `MatchmakerUserConversationsCubit._onIncoming` | Conversations tab | **Updates in-memory** (bump unread, update preview, re-sort) |
| `ReceiveMessage` (colleague convos) | same | `MatchmakerColleagueConversationsCubit._onIncoming` | Colleagues conversations | **Updates in-memory** (same) |
| (connection status) | reconnect signal | `_onStatus` in the 3 list cubits | all matchmaker lists | **Re-fetches page 1** on reconnect to catch up |

> **Implication for caching strategy:** chat messages and the three matchmaker live lists are **push-updated** — they need an initial fetch but should not be polled. The matchmaker reconnect handlers already do a page-1 refresh on resume.

---

## 4. Fetch inventory — what gets re-fetched and when

> **DI rule of thumb:** datasources/repos/usecases are lazySingletons; **list/screen cubits are `factory`**. Because both home shells are `IndexedStack`, a factory cubit's `create` still fires **once per shell lifetime** (the element is kept alive), so "factory" does **not** mean "re-fetch on tab switch" here — see §6.

### 4.1 User app

| Feature | Endpoint (constant) | Caller (cubit → datasource) | Trigger | Frequency |
|---|---|---|---|---|
| Discovery feed | `GET Discovery` (`discovery`) | `DiscoveryCubit` → [discovery_remote_datasource.dart:70](../lib/features/discovery/data/datasources/discovery_remote_datasource.dart#L70) | `loadInitial` / `refresh` / `applyFilters` / auto-prefetch (3 cards from end) | Once on shell mount; again on filter/refresh; paged on scroll |
| Discovery filters | `GET Discovery/filters` (`discoveryFilters`) | `DiscoveryFilterCubit` → [discovery_remote_datasource.dart:100](../lib/features/discovery/data/datasources/discovery_remote_datasource.dart#L100) | First filter-sheet open | Once per sheet open |
| Likes — Sent | `GET likes/outgoing` (`likesOutgoing`) | `LikesCubit` → [likes_remote_datasource.dart:51](../lib/features/likes/data/datasources/likes_remote_datasource.dart#L51) | Lazy on tab activate | Once per cubit life |
| Likes — Received | `GET likes/incoming` (`likesIncoming`) | `LikesCubit` → [likes_remote_datasource.dart:44](../lib/features/likes/data/datasources/likes_remote_datasource.dart#L44) | Lazy on tab activate | Once per cubit life |
| Matches | `GET matches` (`matches`) | `LikesCubit` → [matches_remote_datasource.dart:37](../lib/features/likes/data/datasources/matches_remote_datasource.dart#L37) | Lazy on tab activate; **invalidated after accept-like** | Once, then re-fetch after an accept |
| Chat bootstrap | `GET chat/my-matchmaker` (`chatMyMatchmaker`) | `ChatEntryCubit` → [chat_remote_datasource.dart:47](../lib/features/chat/data/datasources/chat_remote_datasource.dart#L47) | Shell mount (`load`) + pull-to-refresh | Once on mount; on refresh |
| Chat messages | `GET chat/conversations/{id}/messages?page=N` (`chatMessages`) | `ConversationCubit` → [chat_remote_datasource.dart:138](../lib/features/chat/data/datasources/chat_remote_datasource.dart#L138) | Conversation open (page 1, size 30); scroll; reconnect catch-up | On open + paging + reconnect |
| Chat conversations | `GET chat/conversations` (`chatConversations`) | — | **Never called** (future multi-matchmaker) | — |
| Notifications inbox | `GET notifications?page=N` (`notifications`) | `NotificationsCubit` (PaginatedListCubitMixin) → [notifications_remote_datasource.dart:37](../lib/features/notifications/data/datasources/notifications_remote_datasource.dart#L37) | Inbox open; scroll | On open + paging |
| Notifications badge | `GET notifications/count` (`notificationsCount`) | `NotificationBadgeCubit` (**lazySingleton**) → [notifications_remote_datasource.dart:56](../lib/features/notifications/data/datasources/notifications_remote_datasource.dart#L56) | App foreground (FCM stream), on-demand | Variable |
| My profile | `GET profile` (`myProfile`) | `MyProfileCubit` → [profile_remote_datasource.dart:48](../lib/features/profile/data/datasources/profile_remote_datasource.dart#L48) | Profile tab mount; pull-to-refresh | Once on shell mount; on refresh |
| Other profile | `GET discovery/profiles/{id}` (`profileById`) | `ProfileDetailsCubit` → [profile_remote_datasource.dart:66](../lib/features/profile/data/datasources/profile_remote_datasource.dart#L66) | Detail open (uses **seed** from discovery/likes if present, then bg-fetch) | Per detail open (seed avoids skeleton, not the fetch) |
| Basic user | `GET users/{id}` (`userBasic`) | `GetBasicUserUseCase` → [profile_remote_datasource.dart:94](../lib/features/profile/data/datasources/profile_remote_datasource.dart#L94) | On-demand (chat sender name/age) | On-demand |
| Subscription plans | `GET subscriptions/plans` (`subscriptionPlans`) | `SubscriptionPlansCubit` (factory) → [subscriptions_remote_datasource.dart:41](../lib/features/subscriptions/data/datasources/subscriptions_remote_datasource.dart#L41) | **Every paywall/packages open** | Every open — **no cache** |
| Current subscription | `GET subscriptions/current` (`currentSubscription`) | `CurrentSubscriptionCubit` (**lazySingleton, 60s TTL**) → [subscriptions_remote_datasource.dart:59](../lib/features/subscriptions/data/datasources/subscriptions_remote_datasource.dart#L59) | Boot hydrate; force-refresh after like/accept/photo-exchange/subscribe; pull-to-refresh | Boot + after gated actions |
| Questionnaire intake | `GET Questions?gender=…` (`questions`) | `QuestionnaireCubit` → [questionnaire_remote_datasource.dart:33](../lib/features/questionnaire/data/datasources/questionnaire_remote_datasource.dart#L33) | Intake screen mount | Once (cached in cubit) |
| Profile-edit schema | `GET Questions/edit-form` (`editForm`) | `ProfileEditCubit` → [questionnaire_remote_datasource.dart:68](../lib/features/questionnaire/data/datasources/questionnaire_remote_datasource.dart#L68) | **Every edit screen mount** | Every visit — **no cache** |
| Terms / Privacy | `GET terms-and-conditions` / `privacy-policy` (`termsAndConditions`/`privacyPolicy`) | `LegalDocumentCubit` (`_cache` map) → [legal_remote_datasource.dart:30](../lib/features/legal/data/datasources/legal_remote_datasource.dart#L30) | Tab open (cached per type) | Once per type per cubit life |
| Support categories | `GET support/categories` (`supportCategories`) | `SupportCubit` → [support_remote_datasource.dart:32](../lib/features/support/data/datasources/support_remote_datasource.dart#L32) | Help screen mount | Once per cubit life |

### 4.2 Matchmaker app

| Feature | Endpoint (constant) | Caller (cubit → datasource) | Trigger | Frequency |
|---|---|---|---|---|
| Dashboard | `GET matchmaker/dashboard` (`matchmakerDashboard`) | `MatchmakerDashboardCubit` → [matchmaker_dashboard_remote_datasource.dart:29](../lib/features/matchmaker/dashboard/data/datasources/matchmaker_dashboard_remote_datasource.dart#L29) | Shell mount; pull-to-refresh/retry | Once per session (cached); refresh on demand |
| Plan filter rail | `GET matchmaker/users/subscription-plans` (`matchmakerUsersSubscriptionPlans`) | `SubscriptionPlansCubit` (matchmaker) → [matchmaker_users_remote_datasource.dart:77](../lib/features/matchmaker/users/data/datasources/matchmaker_users_remote_datasource.dart#L77) | Mount of subscribed-list tab | Idempotent `load()` — once per cubit life |
| Users: pending | `GET matchmaker/users/pending?page=N` (`matchmakerUsersPending`) | `MatchmakerUsersListCubit` → [matchmaker_users_remote_datasource.dart:33](../lib/features/matchmaker/users/data/datasources/matchmaker_users_remote_datasource.dart#L33) | `loadFirst`/`loadMore`/`refresh` | First page on mount; paged; refresh |
| Users: approved-unsub | `GET matchmaker/users/approved-unsubscribed?page=N` (`matchmakerUsersApprovedUnsubscribed`) | same cubit (per-list instance) | same | same |
| Users: approved-sub | `GET matchmaker/users/approved-subscribed?page=N&planId=P` (`matchmakerUsersApprovedSubscribed`) | same cubit | + **plan-chip change ⇒ server-side re-filter** | First page + every plan-chip change |
| Viewed profile | `GET matchmaker/users/{id}/profile` (`matchmakerUserProfile`) | `MatchmakerProfileDetailCubit` → [matchmaker_user_profile_remote_datasource.dart:23](../lib/features/matchmaker/users/data/datasources/matchmaker_user_profile_remote_datasource.dart#L23) | Profile screen mount; pull-to-refresh | Once per open (cached in cubit) |
| Viewed user — likes out | `GET matchmaker/users/{id}/likes/outgoing` (`matchmakerUserLikesOutgoing`) | `MatchmakerInterestsCubit` → [matchmaker_interests_remote_datasource.dart](../lib/features/matchmaker/interests/data/datasources/matchmaker_interests_remote_datasource.dart) | Lazy on interests sub-tab | Once per tab |
| Viewed user — likes in | `GET matchmaker/users/{id}/likes/incoming` (`matchmakerUserLikesIncoming`) | same | Lazy on sub-tab | Once per tab |
| Viewed user — matches | `GET matchmaker/users/{id}/matches` (`matchmakerUserMatches`) | same | Lazy on matches sub-tab | Once per tab |
| Viewed user — archived | `GET matchmaker/users/{id}/matches/archived` (`matchmakerUserMatchesArchived`) | same (parallel with matches) | With matches load | Once per tab (non-fatal) |
| Viewed user — note (read) | `GET matchmaker/users/{id}/note` (`matchmakerUserNote`) | `MatchmakerUserNotesCubit` | Note sheet mount | Once per sheet open |
| Open chat w/ user | `GET matchmaker/users/{id}/chat` (`matchmakerUserChat`) | `MatchmakerOpenChatCubit` → [matchmaker_conversations_remote_datasource.dart:60](../lib/features/matchmaker/conversations/data/datasources/matchmaker_conversations_remote_datasource.dart#L60) | Row tap → open chat | Per open |
| Cases list | `GET matchmaker/compatibility-cases?page=N` (`matchmakerCompatibilityCases`) | `MatchmakerCasesListCubit` → [compatibility_cases_remote_datasource.dart:34](../lib/features/matchmaker/compatibility_cases/data/datasources/compatibility_cases_remote_datasource.dart#L34) | `loadFirst`/`loadMore`/`refresh`; **realtime reconnect catch-up** | First page + paging + reconnect |
| Case note (read) | `GET matchmaker/compatibility-cases/{id}/my-note` (`matchmakerCompatibilityCaseNote`) | `CaseNoteCubit` | Case-note sheet mount | Once per sheet open |
| User conversations | `GET matchmaker/conversations/users?page=N` (`matchmakerConversationsUsers`) | `MatchmakerUserConversationsCubit` → [matchmaker_conversations_remote_datasource.dart:31](../lib/features/matchmaker/conversations/data/datasources/matchmaker_conversations_remote_datasource.dart#L31) | `loadFirst`/`loadMore`/`refresh`; **realtime + reconnect** | First page + paging + reconnect |
| Colleague conversations | `GET matchmaker/conversations/colleagues?page=N` (`matchmakerConversationsColleagues`) | `MatchmakerColleagueConversationsCubit` → [matchmaker_colleagues_remote_datasource.dart:62](../lib/features/matchmaker/colleagues/data/datasources/matchmaker_colleagues_remote_datasource.dart#L62) | same as above | First page + paging + reconnect |
| Colleagues directory | `GET matchmaker/colleagues?page=N` (`matchmakerColleagues`) | `MatchmakerColleaguesDirectoryCubit` → [matchmaker_colleagues_remote_datasource.dart:40](../lib/features/matchmaker/colleagues/data/datasources/matchmaker_colleagues_remote_datasource.dart#L40) | `loadFirst`/`loadMore`/`refresh` | First page + paging |
| Explore results | `GET matchmaker/explore?page=N&search=…&gender=…&QuestionFilters[..]` (`matchmakerExplore`) | `MatchmakerExploreCubit` → [matchmaker_explore_remote_datasource.dart:38](../lib/features/matchmaker/explore/data/datasources/matchmaker_explore_remote_datasource.dart#L38) | `loadFirst`/`loadMore`; **every search/gender/filter change resets to page 1** | First page + every query change + paging |
| Explore filters | `GET matchmaker/explore/filters` (`matchmakerExploreFilters`) | inline (no dedicated cubit) → [matchmaker_explore_remote_datasource.dart:84](../lib/features/matchmaker/explore/data/datasources/matchmaker_explore_remote_datasource.dart#L84) | **Every filter-sheet open** | Every open |
| Notifications inbox | `GET notifications?page=N` (`notifications`) | `MatchmakerNotificationsCubit` → [matchmaker_notifications_remote_datasource.dart:30](../lib/features/matchmaker/notifications/data/datasources/matchmaker_notifications_remote_datasource.dart#L30) | Inbox open; scroll | On open + paging |
| Notifications badge | `GET notifications/count` (`notificationsCount`) | `MatchmakerNotificationBadgeCubit` (**singleton**) → [matchmaker_notifications_remote_datasource.dart:57](../lib/features/matchmaker/notifications/data/datasources/matchmaker_notifications_remote_datasource.dart#L57) | App resume; on inbox open (`markAllSeen`) | Variable — see §8 (can double-fire) |
| Account | `GET matchmaker/me` (`matchmakerMe`) | `MatchmakerAccountCubit` → [matchmaker_account_remote_datasource.dart:50](../lib/features/matchmaker/account/data/datasources/matchmaker_account_remote_datasource.dart#L50) | Account screen mount | Once per open (no refresh path) |

---

## 5. Offline behavior

### 5.1 Cold start works offline (shell reachable)
Boot reads are **local only** — the app reaches its shell without a network:
- [main.dart:37](../lib/main.dart#L37) `await UserSessionCubit.hydrate()` reads token/role/flags from disk (blocking, but local).
- [main.dart:44](../lib/main.dart#L44) `CurrentSubscriptionCubit.hydrate()` is fire-and-forget (does not block boot).
- `SplashCubit` ([splash_cubit.dart](../lib/features/splash/presentation/blocs/splash_cubit.dart)) routes purely on local `token` + `userRole` + onboarding flags — **no network call at splash**.

> So **offline cold start lands on Home / Matchmaker Home** (if a token exists) or Login/Onboarding (if not). The shell renders; the *content* then fails.

### 5.2 Per-screen offline outcome — **fail after 30s, then error + retry**
There is no offline fast-path, so every first load waits the full 30s timeout, then shows an error state. Representative cases:
- **Discovery:** `loadInitial` times out → `DiscoveryFailure` → `_ErrorView(message, onRetry)` ([discovery_view.dart](../lib/features/discovery/presentation/widgets/discovery_view.dart)). Message is the **generic** `errors_generic` ("الخطأ"), not an offline-specific message. A background prefetch failing on an already-loaded deck is **swallowed** (deck stays visible).
- **Likes/Matches:** each tab's lazy load → failure state → error + retry.
- **Chat conversation:** `init` page-1 fetch times out → failure → error (no offline distinction).
- **Matchmaker lists:** `loadFirst` → failure state on each list.

**No screen renders cached content offline** (other than already-cached images). Any **action** (like, reject, send, approve) requires the network and fails immediately/▸after timeout.

### 5.3 Token edge
`SecureStorageService` reads survive offline (local), so the **shell is reachable**, but there is **no token-refresh**: an expired token yields a 401 → generic `errors_unauthorized` string, with **no auto-relogin** path. (Not strictly an offline case, but the same "generic error, dead end" UX.)

---

## 6. Pagination + in-memory state survival

**Pagination mixin:** `PaginatedListCubitMixin<T>` ([paginated_list_cubit_mixin.dart](../lib/core/state/paginated_list_cubit_mixin.dart)) holds `page`, `items`, `hasMore`, and load flags. Implemented by the 6 matchmaker list cubits + both notifications inbox cubits. `DiscoveryCubit` and `LikesCubit` use their own bespoke paging/lazy-load.

**Key structural fact — both shells are `IndexedStack`:**
- User: [home_screen.dart:128-136](../lib/features/home/presentation/screens/home_screen.dart#L128) builds `DiscoveryView / LikesScreen / ChatEntryScreen / ProfileScreen` once and keeps them alive.
- Matchmaker: `MatchmakerHomeScreen` IndexedStack with 5 tabs (dashboard/users/cases/conversations/explore), realtime owned by the shell.

Because `IndexedStack` keeps every child element mounted, each child's internal `BlocProvider(create:)` runs **once per shell lifetime** — so a `factory` registration does **not** cause a re-fetch on tab switch.

| Scenario | User app | Matchmaker app | Why |
|---|---|---|---|
| **Tab switch within shell** | **Survives** | **Survives** | IndexedStack keeps all tab elements alive; cubit `create` already fired once |
| **Push detail → pop back** | **Survives** | **Survives** | Shell + IndexedStack stay mounted under the pushed route; list cubit untouched (the detail screen uses its own factoryParam cubit, discarded on pop) |
| **Background → resume** | **Survives** (chat pauses/resumes socket + page-1 catch-up) | **Survives** (socket kept alive / reconnects; lists page-1 catch-up) | Widget tree retained; realtime handlers reconcile |
| **Cold start** | **Lost → re-fetch** | **Lost → re-fetch** | Fresh process/DI/tree |
| **Re-login (logout→login)** | **Lost → re-fetch** | **Lost → re-fetch** | New shell instance |

**`KeepAlivePage` / `AutomaticKeepAliveClientMixin`:** [keep_alive_page.dart](../lib/features/matchmaker/users/presentation/widgets/keep_alive_page.dart) (`wantKeepAlive = true`) wraps the matchmaker **users sub-tab `PageView`** pages, so lateral swipes between pending/approved-unsub/approved-sub **preserve each sub-list's pagination** rather than rebuilding.

> **Net:** the "every navigation re-fetches" perception is **no longer true for in-session tab/detail navigation** (IndexedStack fixed it). The remaining re-fetches are **cold start, re-login, realtime reconnect catch-up (cheap, page 1), and the per-open screens with no cache** (paywall plans, profile-edit form, explore filters, every note/detail sheet).

---

## 7. Categorization (recommendation only — no strategy decided)

Endpoints grouped by data volatility. **This is a bucket map for the next planning step, not a decision.**

### A — Static / rarely changes → heavy-cache candidates
- `subscriptions/plans` (`subscriptionPlans`)
- `matchmaker/users/subscription-plans` (`matchmakerUsersSubscriptionPlans`)
- `Questions?gender=…` (`questions`) — intake catalog
- `Discovery/filters` (`discoveryFilters`), `matchmaker/explore/filters` (`matchmakerExploreFilters`)
- `support/categories` (`supportCategories`)
- `terms-and-conditions` / `privacy-policy` (`termsAndConditions` / `privacyPolicy`)

### B — User-owned, changes only on the user's own action → cache + invalidate on mutation
- `profile` (`myProfile`)
- `Questions/edit-form` (`editForm`)
- `subscriptions/current` (`currentSubscription`) — already 60s TTL
- `matchmaker/me` (`matchmakerMe`)
- per-entity notes: `matchmakerUserNote`, `matchmakerCompatibilityCaseNote`

### C — Lists worth "show stale, refresh in background" → stale-while-revalidate candidates
- User: `likes/incoming`, `likes/outgoing`, `matches`, `notifications`
- Matchmaker: `matchmaker/users/{pending,approved-unsubscribed,approved-subscribed}`, `matchmaker/compatibility-cases`, `matchmaker/conversations/users`, `matchmaker/conversations/colleagues`, `matchmaker/colleagues`, `notifications`, the viewed-user `likes/*` and `matches/*`

### D — Realtime / volatile → don't aggressively cache; coordinate with the live channel
- `chat/conversations/{id}/messages` (+ `ReceiveMessage` / `MessagesRead`)
- `matchmaker/compatibility-cases` (+ `CompatibilityCaseUpdated`)
- `matchmaker/conversations/users` & `…/colleagues` (+ `ReceiveMessage`)
- `Discovery` feed (server-curated deck, advances as the user swipes)
- `notifications/count` badges (live-ish via FCM/app-resume)

> Note overlap: the three matchmaker live lists sit in **both C and D** — they are list-shaped (cacheable to render instantly) **and** push-updated (must reconcile with SignalR rather than poll).

---

## 8. Observations: clear waste (flagged only — no fixes proposed)

1. **Notifications: badge and inbox hit the notifications endpoints independently.**
   - User: `NotificationBadgeCubit` calls `getCount()` ([notifications_remote_datasource.dart:56](../lib/features/notifications/data/datasources/notifications_remote_datasource.dart#L56)) separately from `NotificationsCubit` paging `notifications` ([:37](../lib/features/notifications/data/datasources/notifications_remote_datasource.dart#L37)). The count is also fetched as "page 1, size 1" in some paths — a list call purely to derive a number.
   - Matchmaker: `MatchmakerNotificationBadgeCubit.refresh()` and `.markAllSeen()` **both** call `_getCount()` ([matchmaker_notification_badge_cubit.dart:28,43](../lib/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_badge_cubit.dart#L28)) — opening the inbox right after a resume can fire **two `/notifications/count` calls back-to-back**.

2. **Subscription plans re-fetched on every paywall/packages open.** `SubscriptionPlansCubit` is a factory with no cache → `GET subscriptions/plans` ([subscriptions_remote_datasource.dart:41](../lib/features/subscriptions/data/datasources/subscriptions_remote_datasource.dart#L41)) fires every time any of the 3 gates (like/accept/photo-exchange) or the packages screen opens the sheet. Plans are near-static (bucket A).

3. **Profile-edit schema re-fetched every visit.** `GET Questions/edit-form` ([questionnaire_remote_datasource.dart:68](../lib/features/questionnaire/data/datasources/questionnaire_remote_datasource.dart#L68)) on every `ProfileEditCubit` mount, with no TTL — even though the question catalog is effectively static and the user's own answers only change on their own submit (bucket A/B).

4. **Entering either home shell fans out 4–5 parallel GETs at once.** Because `IndexedStack` mounts every tab eagerly ([home_screen.dart:128](../lib/features/home/presentation/screens/home_screen.dart#L128)), the user shell fires **Discovery page-1 + Likes active-tab + chat `my-matchmaker` + `profile`** simultaneously on entry, before the user visits 3 of those tabs. The matchmaker shell similarly mounts dashboard + the first list of each tab. This trades the per-tab spinner (good) for a **burst of upfront fetches**, several of which the user may never look at this session.

5. **Explore filters re-fetched on every filter-sheet open.** `matchmaker/explore/filters` ([matchmaker_explore_remote_datasource.dart:84](../lib/features/matchmaker/explore/data/datasources/matchmaker_explore_remote_datasource.dart#L84)) is fetched inline with no caching cubit — the filter question set is bucket A but reloads each time the sheet opens.

6. **Matchmaker users list re-filters server-side on every plan-chip toggle.** Each chip change re-issues `approved-subscribed?...&planId=P` from page 1 ([matchmaker_users_list_cubit.dart:43](../lib/features/matchmaker/users/presentation/blocs/matchmaker_users_list_cubit.dart#L43)); toggling chips A→B→A re-fetches A from scratch (no per-filter result memo).

7. **Generic error on dead network (no offline distinction).** Because `OfflineFailure` is never thrown (§2), an offline user waits the full 30s and then sees `errors_generic` — indistinguishable from a real server fault, with no "you're offline" affordance.

8. **No duplicate *profile* double-fetch found (positive note).** The other-user profile path uses a **seed** from discovery/likes ([profile_remote_datasource.dart:66](../lib/features/profile/data/datasources/profile_remote_datasource.dart#L66)) to render instantly and fetch once in the background — it does **not** fetch the same profile from two cubits. Flagging it as *not* waste so the next step doesn't "fix" it.

---

## Verification

- **No source file modified** — this audit is read-only; the only new file is this document.
- `flutter analyze lib` and `git status` confirmation appended by the running session below.
