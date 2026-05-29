# Matchmaker (Moderator) — Pre-Implementation Diagnostic

**Status:** Analysis only. No code this turn. Awaiting decisions before M1.
**Backend source of truth:** `MOBILE_MATCHMAKER_FLOW.md` (attached this session).
**Identity / DS:** Locked. Wine `#431C33`, gold `#E4C094`, cream `#FEFCFA`. Material colors forbidden.

---

## Context

A new milestone: implement the Matchmaker (role=Moderator) experience inside the existing Qeran APK. Same identity, same auth, same chat infrastructure, same design system — but a different UI tree after login. The backend dev has delivered an authoritative spec (`MOBILE_MATCHMAKER_FLOW.md`) covering ~40 endpoints across 8 functional areas plus SignalR and FCM behavior. This diagnostic audits what we already have, what we're missing, and proposes a milestone breakdown and the decisions needed from the user before writing M1.

---

## 1. Understanding of the Backend

### Functional surface (what the doc actually delivers)

| Area | Endpoints | Notes |
|---|---|---|
| **Auth** | `POST /auth/login`, `/logout`, `/change-password` | Same shape as user. Response carries `role: "Moderator"`. **No refresh token** — 7-day JWT, re-login on expiry. |
| **Dashboard** | `GET /matchmaker/dashboard` | 6 counters: pending users, approved sub/unsub, active compat cases, unread msgs, total assigned. |
| **Users management** | 3 paginated lists (`pending` / `approved-unsubscribed` / `approved-subscribed`), `GET …/profile`, `POST …/approve`, `POST …/reject` (reason), `POST …/request-image`, `GET …/editable-answers`, `POST …/text-answer`, `GET …/chat` | Profile shape is identical to user's `/api/profile` — same `placements[]` model, but images are **never blurred** and email is visible. Text-answer edits allowed only in `PendingReview` / `Rejected`. |
| **Compatibility cases** | `GET /matchmaker/compatibility-cases`, `POST …/{formalRequestId}/status` | Single denormalized DTO per case carrying both users + photo exchange + formal request. List filters out closed cases (`status>2`). Status transitions emit SignalR `CompatibilityCaseUpdated` to both users + the other matchmaker. |
| **Explore** | `GET /matchmaker/explore`, `GET …/filters` | Browse Visible profiles regardless of assignment. Filters via `QuestionFilters[id]=value` (mirrors discovery API). **No range filters** (caveat). Returns `isMyAssigned` + `assignedMatchmakerName`. |
| **Colleagues (M2M)** | `GET /matchmaker/colleagues`, `POST …/{id}/open-chat`, `GET /matchmaker/conversations/colleagues` | Lazy-create colleague conversation. Conversation type: `MatchmakerToMatchmaker`. |
| **Conversations (M2U)** | `GET /matchmaker/conversations/users`, `GET /matchmaker/users/{id}/chat` (helper) | Wrappers over the **shared** `/api/chat/conversations/{id}/…` endpoints we already use. |
| **Share profile** | `POST /chat/conversations/{id}/share-profile` body `{sharedUserId}` | Already exists in user-side chat. Reused unchanged. |
| **Notifications** | `GET /notifications`, `GET /notifications/count` | History only. **No mark-as-read endpoint, no `IsRead` flag** — doc explicitly flags this as a future schema change. |
| **Account** | `GET/PUT /matchmaker/me`, `POST …/profile-photo` (multipart, 2MB max), `POST …/deactivate` | Edit name only. Photo upload identical to user upload pattern. |
| **Realtime** | `/hubs/chat` | Events: `ReceiveMessage`, `MessagesRead`, `CompatibilityCaseUpdated`. **We already consume the first two.** Methods (`SendMessage`/`ShareProfile`/`MarkAsRead`) are receive-only by current convention — doc agrees. |

### Things in the doc that need clarification from backend dev before M1

1. **`role` value casing:** Doc says login returns `role: "Moderator"`. Our existing splash branches on `role == 'khataba'` (lowercase Arabic transliteration). One of the two is wrong, or both values are emitted historically. **#1 question for backend dev.**
2. **`hasPhoneVerified` exception clause** (§3): "If `role == Moderator` AND `token == ""` → admin forgot to verify phone." Confirm: is `token` actually empty in that case, or just missing? Treat as edge-case for graceful error UI.
3. **Image endpoint shape for profile images:** Doc references `/api/users/profile-images/{guid}` in user lists but `profileImage.url` (already a relative path) in profile details. Confirm we always get a URL we can prepend baseUrl + JWT to, or whether some come fully qualified.
4. **`CompatibilityCaseUpdated` payload (§16):** Doc only lists `{formalRequestId, newStatus, newStatusCode, updatedAt}`. Is the case ID included? Without it, the matchmaker client must keep a `formalRequestId → caseId` index, which is fragile. Worth confirming.
5. **Empty list endpoints behavior:** Most lists are paginated. Confirm `totalCount=0` returns `data: []` (not null) for the standard empty-state path.
6. **FCM payload schemas:** Doc says `data.conversationId`, `data.formalRequestId` for deep-linking — but doesn't fix the JSON keys. Need exact key names before we wire deep-links (M4).

---

## 2. Audit — Infrastructure We Reuse As-Is

| Concern | Where | Verdict |
|---|---|---|
| HTTP client | [http_consumer.dart](../lib/core/api/http_consumer.dart) — `http` package, manual JWT + `Accept-Language: ar` injected in `_getHeaders()` | **Reuse as-is.** Every matchmaker endpoint gets auth + locale for free. |
| Base URL | [end_points.dart](../lib/core/api/end_points.dart) | **Reuse.** Add a `matchmaker` block of constants. |
| Response envelope | [api_response.dart](../lib/core/api/api_response.dart) — `ApiResponse<T>{status,message,errorCode,data}` | **Reuse.** Already matches the doc exactly. |
| Error mapping | `CodedServerException` (errorCode) + `ServerException` (message) + Failure hierarchy + `Either<Failure,T>` via dartz | **Reuse.** errorCodes from the doc (UNAUTHORIZED, PROFILE_NOT_FOUND, etc.) map 1:1. |
| JWT storage | [secure_storage_service.dart](../lib/core/datasources/secure_storage_service.dart) | **Reuse.** |
| Session | [user_session_cubit.dart](../lib/features/auth/presentation/blocs/user_session/user_session_cubit.dart) — app-scoped singleton exposing role/userId/email | **Reuse.** Hydrates from storage on cold start; perfect for the "role-gate every screen" rule. |
| Login flow | Auth feature (data/domain/presentation, BLoC) reads `role` from response into `UserModel` ([user_model.dart](../lib/features/auth/data/models/user_model.dart) line 33) | **Reuse.** No changes to the login screen. |
| Splash routing | [splash_cubit.dart:35-39](../lib/features/splash/presentation/blocs/splash_cubit.dart#L35-L39) already branches on role | **Adapt** (one-liner): replace `'khataba'` with the canonical value once confirmed. |
| Router | [app_router.dart](../lib/core/routes/app_router.dart) + [route_name.dart](../lib/core/routes/route_name.dart) — string-based MaterialPageRoute | **Reuse + extend.** Add `RouteNames.matchmaker*` constants and `case`s. |
| DI | [injection_container.dart](../lib/core/di/injection_container.dart) + per-feature `*_injection.dart` files | **Reuse.** Add `matchmaker_injection.dart` and call it from `init()`. |
| Localization | EasyLocalization + `LanguageService` bridging non-context locale to HTTP layer | **Reuse.** Add Arabic + English strings for matchmaker screens. |
| **Chat module** | [lib/features/chat/](../lib/features/chat/) — full domain/data/presentation with ChatMessageModel, ConversationCubit, REST + SignalR + share-profile | **Reuse heavily.** ChatMessage shape is generic (sender-agnostic). User-side baked-in assumption: it currently bootstraps via `GET /chat/my-matchmaker` (a user-only endpoint). For matchmaker we'd bypass that and open conversations directly via `conversationId` from the matchmaker list endpoints. Architectural twin, not a fork. |
| **SignalR** | [chat_realtime_signalr_service.dart](../lib/features/chat/data/datasources/chat_realtime_signalr_service.dart) — `signalr_netcore`, `withAutomaticReconnect`, JWT via `accessTokenFactory`, subscribes `ReceiveMessage` + `MessagesRead` | **Reuse + extend.** Add a third subscription: `CompatibilityCaseUpdated`. Hub URL, connection lifecycle, reconnect — all already there. |
| **FCM** | [notification_service.dart](../lib/core/services/notification_service.dart) + [device_bootstrap_service.dart](../lib/features/devices/application/device_bootstrap_service.dart) — token request, register (`POST /Devices/register`), link to JWT, refresh-token listener | **Reuse for token plumbing.** Deep-linking handlers are missing (gap §3). |
| Authenticated images | [discovery_blurred_image.dart](../lib/features/discovery/presentation/widgets/discovery_blurred_image.dart) + [like_blurred_image.dart](../lib/features/likes/presentation/widgets/like_blurred_image.dart) — both use `CachedNetworkImage` with JWT in `httpHeaders` and blur driven by **data-layer `isBlurred` flag** | **Reuse.** Backend will set `isBlurred=false` for the moderator — UI conditional already respects the flag. No special-case code needed. |
| Snackbar | [app_snackbar.dart](../lib/core/utils/app_snackbar.dart) | **Reuse.** |
| Image picker | [photo_picker_bottom_sheet.dart](../lib/features/auth/presentation/screens/upload_image/widgets/photo_picker_bottom_sheet.dart) | **Reuse for matchmaker profile-photo upload (§17).** |
| Design system | Tokens + 13 Qeran widgets at [lib/core/design_system/](../lib/core/design_system/) | **Reuse exclusively.** No new tokens, no new widgets unless approved through DS. |
| Bottom nav | [qeran_bottom_nav.dart](../lib/core/design_system/widgets/qeran_bottom_nav.dart) + [home_screen.dart](../lib/features/home/presentation/screens/home_screen.dart) + [home_shell_scope.dart](../lib/features/home/presentation/home_shell_scope.dart) — InheritedWidget shell with tab-switch API | **Reuse the pattern.** Build a `MatchmakerHomeScreen` with its own shell + bottom nav (different tabs). |

**Stub already on disk:** [lib/features/khataba_dashboard/presentation/screens/dashboard_screen.dart](../lib/features/khataba_dashboard/presentation/screens/dashboard_screen.dart) is a one-line placeholder (`Center(Text('DashboardScreen'))`) that splash currently routes to. We will **replace this folder entirely with `lib/features/matchmaker/`** rather than building on top of an inconsistently-named stub.

---

## 3. Gaps — What's Missing

| Gap | Why it matters | Where it lives |
|---|---|---|
| **`role` value mismatch** | Splash uses `'khataba'`, backend doc says `"Moderator"`. One must change. | [splash_cubit.dart:36](../lib/features/splash/presentation/blocs/splash_cubit.dart#L36) |
| **Login → matchmaker routing** | Login completion (post-OTP) currently always lands on user shell. Needs an early branch when `role == Moderator` (skip questionnaire/oath/whatsapp gates entirely). | Login bloc success handler + splash_cubit |
| **No 401 interceptor** | Current code handles 401 inline at each call. With matchmaker's expanded API surface (~30 endpoints) we'll want a single sweep-the-session helper on 401. | New `core/api/` interceptor or extend `http_consumer` |
| **FCM deep-linking** | `NotificationService` registers tokens and refreshes them. **No `onMessage`/`onMessageOpenedApp`/`onBackgroundMessage` handlers exist** that route to a screen from data payload. Required for: chat from notification, compat case from notification. | Extend [notification_service.dart](../lib/core/services/notification_service.dart) + add `core/services/notification_router.dart` |
| **CompatibilityCaseUpdated SignalR event** | Existing hub service only listens to `ReceiveMessage` + `MessagesRead`. Need to add the third event + a domain port + a stream consumed by the cases cubit. | [chat_realtime_signalr_service.dart](../lib/features/chat/data/datasources/chat_realtime_signalr_service.dart) + new domain port |
| **No debounce utility** | Matchmaker Explore has search input. Will need lightweight debounce. | New `core/utils/debouncer.dart` (~15 lines) |
| **No pagination mixin** | Every feature implements pagination locally (chat, discovery). Matchmaker has **6 paginated lists** (3 user tabs, compat cases, explore, 2 conversation lists, notifications). Inlining 6× would be wasteful. Either copy chat's pattern or extract a small `PaginatedListCubit<T>` mixin. | New `core/state/paginated_list_cubit_mixin.dart` (~50 lines) |
| **Existing `khataba_dashboard` stub** | Inconsistent naming. Delete and replace with `features/matchmaker/`. | [lib/features/khataba_dashboard/](../lib/features/khataba_dashboard/) |
| **Locale strings** | All matchmaker screens need ar/en keys. ~80 new strings expected. | `assets/translations/{ar,en}.json` + regenerate `locale_keys.g.dart` |
| **Confirmed-not-needed** | Range filters (doc), notification mark-as-read (doc says future schema change), FCM token refresh (already wired) | n/a |

---

## 4. Proposed Matchmaker Feature Module Structure

Mirror existing convention (discovery / chat as templates). Single top-level feature with a subfolder per functional area so each milestone touches a cohesive slice. Each subfolder follows `data/domain/presentation` internally.

```
lib/features/matchmaker/
├── di/
│   └── matchmaker_injection.dart
├── shared/                                  # cross-area infra used by ≥2 subareas
│   ├── data/datasources/matchmaker_api.dart   # base URL constants + shared GETs
│   ├── domain/entities/matchmaker_role_gate.dart  # session check helper
│   └── presentation/widgets/
│       ├── matchmaker_app_bar.dart          # composes QeranAppBar
│       ├── matchmaker_paginated_list.dart   # pull-to-refresh + infinite scroll
│       └── matchmaker_user_avatar.dart      # auth-headered image + unblurred
├── home/                                    # the shell + bottom nav
│   ├── presentation/screens/matchmaker_home_screen.dart
│   ├── presentation/home_shell_scope.dart   # mirrors user-side
│   └── presentation/widgets/matchmaker_bottom_nav.dart  # composes QeranBottomNav
├── dashboard/                               # M2
│   ├── data/{models,datasources,repositories}
│   ├── domain/{entities,repositories,usecases}
│   └── presentation/{blocs,screens,widgets}
├── users/                                   # M2 — 3 tabs + profile detail + approve/reject/request-image + editable answers
│   ├── data/...
│   ├── domain/...
│   └── presentation/...
├── compatibility_cases/                     # M3
│   ├── data/...
│   ├── domain/...
│   └── presentation/...
├── conversations/                           # M4 — wrappers over chat module
│   ├── data/datasources/matchmaker_conversations_remote_datasource.dart
│   ├── domain/...
│   └── presentation/{blocs,screens,widgets}   # screens compose existing chat widgets
├── explore/                                 # M5
│   ├── data/...
│   ├── domain/...
│   └── presentation/...
├── colleagues/                              # M4 — companion to conversations
│   ├── data/...
│   ├── domain/...
│   └── presentation/...
├── notifications/                           # M6 (or share with user-side if generalizable)
│   ├── data/...
│   ├── domain/...
│   └── presentation/...
└── account/                                 # M6
    ├── data/...
    ├── domain/...
    └── presentation/...
```

Repositories that touch chat reuse `ChatRepository` from the existing chat feature (no fork). Compat-case stream lives in the matchmaker module, reading from a new domain port in chat.

---

## 5. Suggested Milestone Breakdown

Revised from the original 6-milestone sketch to **6 milestones with redrawn boundaries**. Reasoning: the dashboard + users-management lists share the same paginated-list infrastructure and visual rhythm — they should ship together. SignalR's third event and FCM deep-linking are coupled (both about cross-app notifications), so they belong together in M4. Account + notifications + final polish naturally cluster as M6.

| M | Title | Scope | Why this cut | Deliverable shape |
|---|---|---|---|---|
| **M1** | Routing + shell skeleton | Replace `khataba_dashboard` stub. Confirm `role` value, branch in splash + post-login. Build `MatchmakerHomeScreen` shell with bottom nav (5 tabs: Dashboard, Users, Compat Cases, Conversations, Explore). Each tab = empty `QeranEmptyState`. Add `matchmaker_injection.dart`. Add base API constants in `EndPoints`. Add `MatchmakerRoleGate` helper. Add paginated-list mixin to `core/`. | Foundation only. Wrong-cut here cascades into M2-M6. **Single coherent commit:** "feat(matchmaker): role-gated shell with bottom nav scaffold". | Logging in as a matchmaker test account shows the new shell with 5 empty tabs. No data yet, but tab switching, app bar, bottom nav, and identity colors all verifiable visually. |
| **M2** | Dashboard + Users management | `GET /dashboard` populates 5 stat cards. Pending/Approved-Unsub/Approved-Sub paginated tabs. Tap → profile detail (reuses `placements` rendering pattern from user-side `ProfileBody`). Approve / Reject (with reason bottom sheet) / Request image. Editable answers screen. | Both lean on the same paginated-list infra + the same profile-detail renderer. Splitting them creates duplicated test surface. | Stats render. All 3 tabs paginate and pull-to-refresh. Profile detail opens. Approve/reject round-trips persist. |
| **M3** | Compatibility cases | List + the denormalized DTO renderer + status update flow (1↔2 and closures). | Standalone domain. Doesn't depend on M4 SignalR — REST refresh is fine v1 (real-time live updates layered in M4). | Cases list paginates. Status updates persist and reflect on refresh. |
| **M4** | Conversations + SignalR + FCM deep-linking | (a) Matchmaker conversations list with users + with colleagues (separate sub-tab). (b) `Open chat` helper opens existing chat screen with role-aware bootstrap (skip `/chat/my-matchmaker`). (c) Add `CompatibilityCaseUpdated` SignalR subscription + live-update M3's case list/detail. (d) FCM `onMessage` / `onMessageOpenedApp` handlers route to chat / compat case by data payload. | The three are one coherent "cross-app realtime + push" theme. Compat-case live updates only become real once §c lands, so it makes sense to deliver them together. | Conversations list works. Live messages stream in. Push notifications open the right screen from cold/foreground. Compat cases auto-refresh on hub event. |
| **M5** | Explore + Share-profile | Explore search/grid/filters using existing filter UI patterns. Share-profile flow: pick a conversation (with-user or with-colleague), call `share-profile`. | Once conversations from M4 exist, share-profile becomes simple. | Search/grid/filters work. Sharing into any conversation type works. |
| **M6** | Notifications + Account + polish | Notifications history screen. Account screen (view name/email/phone, edit name, change profile photo, change password, deactivate with confirm). Final polish pass: empty states, error states, motion (ScaleIn for hero, staggered list reveal), wine-tinted shadows audit, snackbar consistency, locale strings sweep. | The two are independent thin features. Polish naturally lives at the end. | All matchmaker features look identity-correct, animations match user-side hero rhythm, ar/en complete. |

**Verification at each milestone:** start the app, log in as a matchmaker test account, walk the scope manually, watch for visual regressions vs identity PDF.

---

## 6. Technical Decisions Needed Before M1

These are the questions to answer before writing M1. (Some need the backend dev's input — flagged with 🛰.)

1. **🛰 Canonical `role` value.** Doc says `"Moderator"`, existing splash branches on `'khataba'`. Which is wire-true? Ask backend dev. Until confirmed, M1 can defensively accept both (`role.toLowerCase() == 'moderator' || role == 'khataba'`) but we should converge on one value.
2. **Routing model.** Two viable cuts:
   - (a) **Single router, role-gated cases**: `RouteNames.matchmaker*` constants live in the same `route_name.dart`, `app_router.dart` handles them. Simple, follows existing convention.
   - (b) **Separate matchmaker router**: a `MatchmakerRouter` exported from the matchmaker feature, with `app_router` dispatching to it on role match.
   - Recommended: **(a)** for consistency. The matchmaker is a different UI tree, not a different navigation framework.
3. **Bottom nav vs no bottom nav.** Doc implies dashboard + users + cases + conversations + explore are all peer-level entry points → a 5-tab bottom nav fits. Confirm or propose alternative (e.g., 4 tabs + Explore inside Users).
4. **`UserSessionCubit` extension or wrapping.** Matchmaker session has slightly different fields (e.g., no `hasAnsweredQuestions`, but maybe `assignedUsersCount`). Either extend `UserEntity` to carry both shapes (with nullable role-specific fields) or wrap with a `MatchmakerSession` view-model. Recommend: keep `UserEntity` and pull matchmaker-specific stats only via `GET /matchmaker/me` when needed.
5. **JWT expiry UX (7-day, no refresh).** Doc is explicit: re-login on 401. Confirm: a generic "session expired" dialog → push to login + clear storage. No silent refresh attempts.
6. **Dashboard caching.** Cache stats in memory for the session, or always refetch on tab focus? Recommend: in-memory cache + pull-to-refresh + auto-refresh on cold start. Stats change rarely enough.
7. **`CompatibilityCaseUpdated` v1 strategy.** Two options before M4 lands: (a) refresh the list on any event, dropping the payload (simpler), or (b) merge in place by `formalRequestId` (better UX, requires the case ID — see §1 caveat). Recommend (a) for v1, (b) in M4 if backend confirms case-ID-in-payload.
8. **Chat module reuse — bootstrap divergence.** User-side `ChatEntryCubit` bootstraps via `GET /chat/my-matchmaker`. Matchmaker has no equivalent — it just opens conversations from list endpoints. Cleanest fix: parameterize the bootstrap (e.g., `ChatBootstrapMode.matchmaker | user`) or build a thin `MatchmakerChatEntryCubit` next to it. Recommend: thin separate cubit, share the conversation screen.
9. **Notifications module — shared or new?** User-side already has a notifications feature folder ([lib/features/notifications](../lib/features/notifications)). If the schema is identical, we reuse. If matchmaker-specific (e.g., includes "new user assigned"), we may need a small adapter. Confirm by skim.
10. **🛰 FCM payload schema.** Need exact key names for `data` (e.g., `conversationId`, `formalRequestId`, `type`) so the deep-link router in M4 can switch reliably.

---

## 7. Risks & Open Questions

- **Image URLs + auth headers.** Risk: any code path that bypasses `CachedNetworkImage` with `httpHeaders` and uses raw `Image.network` will silently 401. Mitigation: an audit grep in M2 for `Image.network` in matchmaker code + a `MatchmakerUserAvatar` widget that's the only way to render a profile image inside the matchmaker module.
- **Blur conditional.** Backend says matchmaker always sees `isBlurred=false`. Risk: if the backend ever sets `true` for a moderator response, the user-side blur widget would honor it. Mitigation: don't reuse `DiscoveryBlurredImage` / `LikeBlurredImage` directly in matchmaker code — wrap with a `MatchmakerUserAvatar` that asserts unblurred. Defense in depth.
- **SignalR reconnect race.** Existing service handles reconnect, but after reconnect the cubits need to backfill (compat case state, conversation tail). Already a known pattern in chat — replicate for compat cases in M4.
- **FCM token rotation while logged in.** `device_bootstrap_service` re-registers on refresh. But the existing flow assumes a user-role token. Confirm device registration is role-agnostic on the backend (likely yes — it's about the device, not the role).
- **Two stale entries to clean.** `khataba_dashboard` feature folder + the `'khataba'` literal in splash. Both go in M1.
- **Pagination consistency.** 6 paginated lists. If we don't extract a small mixin, we'll fight inconsistency bugs at M5/M6. Recommend extracting in M1.
- **Long screens, file-size cap (200 lines).** Profile detail (with all placements), case detail (denormalized DTO with photo exchange + formal request + both users), and account screen will easily exceed 200 lines if not decomposed early. Plan widget extraction inside each milestone, don't defer.
- **Locale coverage.** ~80 new strings. If we don't add them incrementally per milestone, we'll have one massive translation PR at the end. Recommend: each milestone owns its keys.
- **No range filters in Explore.** The doc admits this and says they're not supported there (only in user-side discovery). UI must hide range-filter affordances even if the filter list endpoint surfaces range-typed questions.

---

## Verification approach (applies at every milestone)

1. Start the app via the `run` skill or the existing dev launch path.
2. Log in with a matchmaker test account → land on `MatchmakerHomeScreen`.
3. Walk the milestone's scope manually: every new screen, every state (loading, empty, error, populated), every action round-trips against the real backend.
4. Sanity-check identity: no Material colors, no gray shadows, no `BorderRadius.circular(N)` literals in new code, all elevations from `QeranShadows`, all text from `QeranTypography`.
5. Sanity-check user-side wasn't disturbed: log in as a user, do a basic discovery + chat flow.
6. Commit only after both walkthroughs pass.

---

**End of diagnostic. Awaiting decisions on §6 before drafting M1.**
