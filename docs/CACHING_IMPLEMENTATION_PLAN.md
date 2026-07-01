# Caching & Connectivity — Implementation Plan (Tier A, APPROVED — final review)

> **Status:** Plan APPROVED by Anas; his answers to S1–S10 folded in and all six cosmetic calls (C1–C6) decided by me below. Still **PLAN ONLY** — no source touched, no pubspec edit, no `connectivity_plus` add yet, no commits. **STOP for one final review of this updated plan before implementation begins.**

---

## TL;DR

Five approved pieces on one shared **foundation** (`ConnectivityService` + a **standalone** `OfflineException` that fast-fails and flows to a **post-login-only** offline banner). The spine is `executeApiCall` ([base_repository.dart:10](../lib/core/data/repositories/base_repository.dart#L10)) — the single place every exception becomes a `Failure` — so offline propagation is **one catch clause**. `OfflineFailure` + `errors_offline` already exist; so does `MaterialApp.builder` (banner mount) and `UserSessionAuthenticated` (the clean post-login gate, already root-provided). Bucket-A caching is **session-long, in-memory, per-repo nullable field + one invalidate hook** (no TTL, no TimedCache abstraction). Lazy-mount is presentation-only in the two shell `State` classes and leaves the shell-owned matchmaker SignalR untouched. Cosmetics: a restrained **wine bar with gold wifi-off icon**, top-anchored, slide-in on `QeranMotion.standard`, no green, no new tokens, no new locale keys. Execution is **sequential, one piece at a time, and each device-verified piece is committed AND pushed immediately** (no local pile-up).

---

## Answered decisions (self-contained summary)

**Semantic (Anas):**
- **S1** Connectivity = `connectivity_plus` + `SocketException` mapping. **No** active reachability ping.
- **S2** Fast-fail = **both** a pre-flight gate and `SocketException` mapping.
- **S3** `OfflineException` is **standalone** (`implements Exception`), **not** a `ServerException` subtype; caught **first** in `executeApiCall`.
- **S4** In-flight requests when the link drops are **left to fail fast** — no cancellation logic.
- **S5** Cache = **session-long, in-memory** for all three (plans, edit-form, explore-filters). **No time-based TTL** — cache lives until app kill or a mutation invalidates it.
- **S6** `submitAnswers` success is the **only** edit-form invalidation trigger. → *Confirm at impl that no other client path mutates the user's own answers; flag before coding if one exists.*
- **S7** Badge fix = **coalesce in-flight** (`CurrentSubscriptionCubit` pattern).
- **S8** Lazy-mount = **keep-alive after first visit** (defers initial mount only; alive-after-mount behavior unchanged).
- **S9** Banner = **post-login only**, role-agnostic. Hidden on splash + pre-login auth (login/register/forgot/OTP/whatsapp). Shown from authentication onward, including post-login onboarding (gender/questionnaire/oath/upload) and both shells. **Gate = `UserSessionCubit.state is UserSessionAuthenticated`** — already root-provided at [qeran_app.dart:39](../lib/qeran_app.dart#L39); clean signal, **no gap**.
- **S10** Splash/boot stays local-only — **no** connectivity check added there.

**Process (Anas):**
- **P1** **Commit + push per piece.** Every device-verified piece is committed and pushed to `origin/main` in the same step. No batch-at-end; the "~95 unpushed commits" pattern must not recur.
- **P2** **Cache simplification.** S5 = session-long ⇒ drop the `TimedCache<Duration>` idea. Use a **bare nullable field per repository + explicit `invalidate()`** where needed. No shared cache abstraction (three trivial call sites don't warrant it).

**Cosmetic (delegated to me — decided as a unified set in Piece 1 / 1b below):** C1 top · C2 wine bar + gold wifi-off icon · C3 no restored-toast, banner just leaves · C4 slide-in `QeranMotion.standard` · C5 yes, offline-specific retry copy/icon · C6 `QeranConnectivityBanner` / `ConnectivityCubit` / `ConnectivityService`.

---

## Out of scope (Anas's "ما تعمل" — do NOT drift)

❌ Local DB (Hive/sqflite/isar) · ❌ full SWR for Bucket-C · ❌ offline-first rework · ❌ any SignalR change · ❌ Bucket-D caching · ❌ token-refresh / 401 handling. If a sub-step seems to need one of these, **STOP and flag** rather than expand scope.

---

## Investigation approach (why single-pass)

Evidence-gathering fan-out already happened ([CACHING_INVESTIGATION.md](CACHING_INVESTIGATION.md), 4 parallel sweeps). Planning is synthesis — one author holding the whole interlock (error flow · DI lifetimes · two shells · design system) beats re-slicing. I re-read the load-bearing files directly to ground every decision: `base_repository.dart`, `errors.dart`, `exceptions.dart`, `http_consumer.dart`, `injection_container.dart`, `qeran_app.dart`, `main.dart`, both shell `State` classes, `user_session_state.dart`, `matchmaker_notification_badge_cubit.dart`, `likes_remote_datasource.dart`, and the design-system token/widget catalog. Fan-out belongs in *implementation*, not here — and even there we run sequential (see Execution).

---

## Architectural foundations (shared by pieces 1 & 2)

### F1 — `ConnectivityService` (new core service) — *Decided: S1*
- **New:** `lib/core/services/connectivity_service.dart` — abstraction over `connectivity_plus`:
  ```
  abstract class ConnectivityService {
    Future<bool> get isOnline;        // snapshot
    Stream<bool> get onStatusChange;  // distinct online/offline transitions
  }
  ```
- `registerLazySingleton<ConnectivityService>()` in [injection_container.dart](../lib/core/di/injection_container.dart) under `//! Network`, **before** `ApiConsumer`.
- **Dep add (impl phase, not now):** `connectivity_plus` in `pubspec.yaml`. Interface-state only → reachability is covered reactively by the `SocketException` mapping (S1), **no** ping.

### F2 — `OfflineException` → `OfflineFailure` spine — *Decided: S2, S3, S4*
- **New standalone type** in [exceptions.dart](../lib/core/errors/exceptions.dart): `class OfflineException implements Exception` — **not** a `ServerException` subtype, so `on ServerException` classifiers (likes/matches) never catch or misread it.
- `OfflineFailure` + `LocaleKeys.errors_offline` **already exist** ([errors.dart:38-40](../lib/core/errors/errors.dart#L38); `ar/en.json:21`) — nothing added there.
- **Modify** [base_repository.dart](../lib/core/data/repositories/base_repository.dart): add `on OfflineException` as the **first** catch → `Left(OfflineFailure())`. One change, all repos.
- **Modify** [http_consumer.dart](../lib/core/api/http_consumer.dart):
  - Inject `ConnectivityService`.
  - **Pre-flight gate (S2):** shared guard at the top of each verb — `if (!await connectivity.isOnline) throw OfflineException();` (instant, no 30 s wait).
  - **Reactive fallback (S1/S2):** map `SocketException` (+ connection-failure `ClientException`) to `OfflineException`; add `if (e is OfflineException) rethrow;` **before** the existing `throw ServerException(...)` wrap.
  - **In-flight (S4):** no cancellation — a request already in flight when the link drops just `SocketException`-fails fast into `OfflineException`.
- **Required audit sub-step:** grep data sources for blanket `catch (e)`/`catch (_)` that could swallow `OfflineException` before `executeApiCall`. Likes/matches use `on ServerException` (safe) — verify, don't assume.

### F3 — Session-long repo cache (Bucket A) — *Decided: S5, P2*
- **No `TimedCache`, no Duration, no `lib/core/cache/` helper.** Each owning **lazySingleton repository** holds a **bare nullable field** for the cached model and returns it when present; only edit-form gets an `invalidate()` that nulls the field.
- In-memory only; dies on cold start (acceptable — Bucket A is static and cheap to refetch once per session). Leaner than an abstraction for three trivial sites (P2).

### F4 — Banner mount point — *Decided: S9*
- `MaterialApp.builder` ([qeran_app.dart:58](../lib/qeran_app.dart#L58)) already wraps the navigator (ResponsiveBreakpoints). The banner composes there, above the `Navigator`, gated by **both** `ConnectivityCubit == offline` **and** `UserSessionCubit.state is UserSessionAuthenticated` (both already root-provided). One place, both roles, zero per-screen wiring, and correctly hidden pre-login.

---

## Per-piece design

### Piece 1 — Offline detection + banner  *(depends on F1)*
**Goal:** a restrained, identity-correct banner shown whenever an **authenticated** device is offline; auto-hides on reconnect. Both roles.

**Design:**
- **New:** `lib/core/connectivity/connectivity_cubit.dart` (`ConnectivityCubit` + `ConnectivityState` online/offline) subscribed to `ConnectivityService.onStatusChange`; added to the root `MultiBlocProvider` ([qeran_app.dart:36](../lib/qeran_app.dart#L36)).
- **New DS widget:** `lib/core/design_system/widgets/qeran_connectivity_banner.dart` — tokens only, `*Directional`, bidirectional.
- **Modify** [qeran_app.dart](../lib/qeran_app.dart): in `builder`, wrap the responsive child so the banner sits above the navigator, shown only when offline **and** `UserSessionAuthenticated`.

**Unified cosmetic decisions (C1–C4, C6):**

| # | Decision | One-line rationale (identity / DS) | Token / locale impact |
|---|---|---|---|
| **C1** | **Top-anchored**, flush full-width, inside top `SafeArea`. | Both shells are `extendBody: true` with a bottom nav — bottom would collide; top is the conventional, unobstructed home for a system-status strip. | none |
| **C2** | **Wine bar (`QeranColors.wine`)** with a **gold (`QeranColors.gold`) `wifi_off_rounded` icon** + **soft-white (`QeranColors.creamCanvas`) label**. Not `danger`. | Offline is an ambient *status*, not a user error — `danger` red would read alarmist/"dating-app loud"; wine is the sanctioned dark overlay identity, gold-on-wine is the app's signature calm-confident pairing and stays legible. | no new color (wine/gold/creamCanvas exist); reuse smallest existing `QeranTypography` label style (add one only if none fits — flag at impl) |
| **C3** | **No "restored" toast.** On reconnect the banner simply animates away. | Restraint — once content reloads, a green/gold confirmation is redundant noise (and success-gold on a transient bar would feel celebratory for a non-event). | **no new locale key** — only `errors_offline` (exists) |
| **C4** | **Slide-in from top on offline, slide-out on reconnect**, `QeranMotion.standard` (280 ms) + `QeranCurves.standard` (easeOutCubic). | `standard` is literally the token doc's "snackbar entry" duration — matches the app's motion vocabulary exactly. | none |
| **C6** | Names: `QeranConnectivityBanner` (DS widget) · `ConnectivityCubit`/`ConnectivityState` · `ConnectivityService`/`ConnectivityServiceImpl`. | Matches DS + feature naming conventions. | none |

Copy: reuse `errors_offline` — AR "لا يوجد اتصال بالإنترنت" / EN "No Internet Connection" (already natural + calm). **Net new tokens: 0. Net new locale keys: 0.** (Only contingency: if no existing `QeranTypography` style is small enough for a status strip, add one small label token — decided at impl, reported at the checkpoint.)

**File map:** new `connectivity_cubit.dart`, new `qeran_connectivity_banner.dart`; modify `qeran_app.dart`.

**Sub-steps (STOP after each):** (1) `ConnectivityCubit` + root wiring (verify emits via logs) → (2) `QeranConnectivityBanner` widget in isolation → (3) compose into `builder` with the auth gate; airplane-mode test logged-in AND on the login screen (must NOT show pre-login).

**Verification:** scoped `flutter analyze lib/core`; **legacy-grep gate ZERO** on the new widget; device airplane-mode toggle (appears/leaves; hidden pre-login, shown in onboarding + both shells); AR + EN / RTL + LTR.

---

### Piece 1b — Offline-specific copy on retry screens  *(depends on Piece 2)*  — *Decided: C5*
**Goal:** when a screen's failure is specifically `OfflineFailure`, its existing error surface reads "no internet" (actionable) instead of the generic error.
- **Message is automatic:** `OfflineFailure.message == errors_offline`, so any screen already rendering `failure.message` shows the right text with **zero** change.
- **Additive polish:** where a screen can see the failure *type*, pass `Icons.wifi_off_rounded` to `QeranErrorState` (its `icon` param already exists — [qeran_error_state.dart:15](../lib/core/design_system/widgets/qeran_error_state.dart#L15)) instead of the default error glyph. Kept **minimal** — only screens that already branch on failure type; no cubit re-plumbing.
- **File map:** touch only the handful of error-render sites that expose failure type. Its own commit/checkpoint. No new tokens/keys.
- **Verification:** offline on discovery + a matchmaker list → wifi-off icon + offline copy; a real 500 still shows the generic error; AR + EN.

---

### Piece 2 — `OfflineFailure` propagation + fast-fail  *(F1 + F2)* — *Decided: S1–S4*
**Goal:** offline requests fail **instantly** with a typed `OfflineFailure` instead of a 30 s hang → generic error.

**File map:** modify `exceptions.dart` (+`OfflineException`), `base_repository.dart` (+first catch), `http_consumer.dart` (+service, +pre-flight guard, +`SocketException` mapping), `injection_container.dart` (register service, inject into `HttpConsumer`); + data-source swallow audit.

**Sub-steps (STOP after each):** (1) `ConnectivityService` abstract+impl + DI *(flags the `connectivity_plus` pubspec add at this checkpoint)* → (2) `OfflineException` + `executeApiCall` catch (compiles, no behavior change) → (3) `HttpConsumer` pre-flight + `SocketException` mapping + inject → (4) run the swallow audit, fix any blanket catch.

**Verification:** scoped `flutter analyze lib/core`; airplane-mode on discovery, a matchmaker list, chat → **instant** offline error (not a 30 s spinner); a genuine server error still reads as server (no false "offline"); AR + EN.

---

### Piece 3 — Cache Bucket-A static endpoints  *(F3)* — *Decided: S5, S6, P2*
**Goal:** stop re-fetching near-static catalogs every open: `subscriptions/plans`, `Questions/edit-form`, `matchmaker/explore/filters`.

**Design (bare nullable field in each lazySingleton repository; cubits stay `factory`):**
- **`subscriptions/plans`** — cache field, return if present; no invalidation (read-only catalog). Kills "every paywall open re-fetches" (Investigation §8.2).
- **`Questions/edit-form`** — cache field **+ `invalidate()` on `submitAnswers` success** (S6 — the only mutation of my own answers). Kills "every edit-screen visit re-fetches" (§8.3). *Confirm at impl no other client path mutates my answers; flag if found.*
- **`matchmaker/explore/filters`** — cache field; today fetched inline every filter-sheet open (§8.5). Confirm exact repo path + whether to move the inline fetch behind the repo at impl.

**File map (verify exact paths at impl):** subscriptions repo impl, questionnaire repo impl, matchmaker-explore repo impl. **No** `lib/core/cache/` helper.

**Sub-steps (STOP after each):** plans → edit-form (+invalidation) → explore-filters, each independently verifiable.

**Verification:** scoped `flutter analyze` per feature; **HTTP-log gate** — open paywall / edit / explore-filter **twice**, second open fires **no** GET; edit-form **does** refetch after an answers submit; scope-diff shows only data layer touched.

---

### Piece 4 — Fix `/count` double-fire  — *Decided: S7*
**Goal:** stop `MatchmakerNotificationBadgeCubit` firing `GET /notifications/count` twice when the inbox opens right after a resume.
**Design:** `refresh()` and `markAllSeen()` each call `_getCount()` today ([matchmaker_notification_badge_cubit.dart:29,44](../lib/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_badge_cubit.dart#L29)). Fix = **coalesce in-flight** via a shared `Future<int>? _inflight` (the `CurrentSubscriptionCubit` pattern) so back-to-back callers await one fetch; keeps the count authoritative.
**File map:** `matchmaker_notification_badge_cubit.dart` only.
**Verification:** scoped `flutter analyze`; HTTP-log gate — resume then open inbox → **one** `/count`, badge clears; AR + EN numerals.

---

### Piece 5 — Lazy-mount IndexedStack tabs  — *Decided: S8*
**Goal:** stop the "enter shell → 4–5 parallel GETs" burst (§8.4). Each tab fetches on **first visit**, then stays alive.
**Design (presentation-only, both shells):** track `Set<int> _visited` (seed the initial tab) in `_HomeScreenState` ([home_screen.dart](../lib/features/home/presentation/screens/home_screen.dart)) and `_MatchmakerHomeScreenState` ([matchmaker_home_screen.dart](../lib/features/matchmaker/home/presentation/screens/matchmaker_home_screen.dart)); render `const SizedBox.shrink()` for unvisited indices, the real tab once visited, and **keep it after** (never revert) → state survival unchanged (S8). Mark visited in `initState` + `_selectTab`.
**SignalR safety:** the matchmaker realtime port is created in `initState` and owned by the shell `State` ([matchmaker_home_screen.dart:60](../lib/features/matchmaker/home/presentation/screens/matchmaker_home_screen.dart#L60)) — tab-body-independent; the dashboard cubit is provided above the stack and the bell badge is primed in `initState`. Lazy-mount touches none of them. ✅
**File map:** `home_screen.dart` + `matchmaker_home_screen.dart` only — shell `State` logic (deliberate, in-scope behavior change, flagged per CLAUDE_CODE §3).
**Sub-steps (STOP after each):** user shell → matchmaker shell.
**Verification:** scoped `flutter analyze` each shell; HTTP-log gate — entering Home fires only Discovery (resp. Dashboard); first visit to each other tab fires its GET once; switch-away-and-back fires none; matchmaker realtime still connects on mount and cases/conversations still live-update; AR + EN.

---

## Execution strategy (sequential; commit + push per piece)

**Order** (dependency- + value-driven, **not** 1→5):
1. **Foundation + Piece 2** (ConnectivityService → OfflineException → fast-fail) — the spine; highest-value; prerequisite for the banner.
2. **Piece 1** (banner) — needs `ConnectivityService`.
3. **Piece 1b** (offline retry copy) — needs Piece 2's typed failure.
4. **Piece 4** (badge double-fire) — tiny, isolated confidence win.
5. **Piece 5** (lazy-mount) — independent, presentation-only; verify burst-drop + SignalR regression.
6. **Piece 3** (Bucket-A cache) — independent, data-layer; per-repo HTTP-log verification.

**Why sequential (not parallel):** 1/1b/2 share the connectivity layer and must land in dependency order. 3/4/5 are independent and *could* fan out, but each needs its **own** device / offline / HTTP-log verification, and Tier-A mandates a STOP-for-check between sub-steps — parallel edits would collapse those gates into one review. **Recommend sequential**; parallel only if you explicitly trade verification granularity for speed.

**Dependency graph:** `F1 → {Piece 2, Piece 1}` · `Piece 1b → Piece 2` · `Piece 3, 4, 5` independent.

---

## Commit + push plan (conventional commits — **push per piece**, P1)

> After each piece is **device-verified**, commit its logical group **and immediately `git push origin/main`** — never accumulate locally. Never stage `qeran_colors.dart`, `docs/`, `web/`, `.metadata`, the kotlin dir, `data.json`; the `pubspec.yaml`/`pubspec.lock` `connectivity_plus` add is staged **only with explicit confirmation** at that checkpoint.

| Step | Piece | Commit(s) in the group | Push |
|---|---|---|---|
| 1 | Piece 2 (+F1/F2) | `build(deps): add connectivity_plus` **+** `feat(core): connectivity service + OfflineException fast-fail` | push both after verify |
| 2 | Piece 1 | `feat(core): post-login offline banner (both shells)` | push after verify |
| 3 | Piece 1b | `feat(core): offline-specific copy on retry screens` | push after verify |
| 4 | Piece 4 | `fix(matchmaker): coalesce notification /count double-fire` | push after verify |
| 5 | Piece 5 | `perf(shell): lazy-mount IndexedStack tabs (user + matchmaker)` | push after verify |
| 6 | Piece 3 | `perf(subscriptions): cache plans` · `perf(questionnaire): cache edit-form + invalidate on submit` · `perf(matchmaker): cache explore filters` | push after each (or the trio) verify |

Every push leaves `origin/main` in sync (0 ahead) before the next piece starts.

---

## Remaining flags (not blocking — resolved at implementation, reported at the checkpoint)

All open *questions* are answered. Only these **confirm-at-impl** items remain (each is a "verify then proceed," to be reported at its checkpoint, not a decision needing Anas now):

1. **S6 edit-form mutations** — confirm `submitAnswers` success is the *only* client path that changes my own answers before wiring `invalidate()`; **flag if another exists**.
2. **Typography contingency (C2)** — if no existing `QeranTypography` label style is small enough for a status strip, add one small label token (name + value reported at the Piece 1 checkpoint).
3. **Explore-filters repo path (Piece 3c)** — confirm exact repo file + whether to move the inline filter fetch behind the repo.
4. **Data-source swallow audit (Piece 2.4)** — grep for blanket catches that could intercept `OfflineException`; report findings.

---

## Verification gates (every piece, before "done")

Scoped `flutter analyze lib/<feature>` clean · **legacy-grep gate ZERO** on new/edited DS widgets (`AppColors|AppTextStyles|AppDimens|CustomButton|AppTextFormField|Color(0x|BorderRadius.circular|CircularProgressIndicator`) · scope-diff (UI pieces = presentation only; data pieces = data only; Piece 5 is the one deliberate shell-`State` change, flagged) · manual **AR + EN** (RTL/LTR) · **airplane-mode** device test (Pieces 1, 1b, 2) · **HTTP-log gate** (Pieces 3, 4, 5) · files < 200 lines, functions < 30 · **commit + push** before the next piece.
