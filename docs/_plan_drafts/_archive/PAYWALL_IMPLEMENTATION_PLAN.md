# Paywall / Purchase Flow — Implementation Plan

> Status: **APPROVED (2026-07-02) with Q-A/B/C decisions folded in — implementation in progress, Commit 1 first.**
> Feature: `lib/features/subscriptions/` + RevenueCat (`lib/core/services/revenuecat_service.dart`, SDK `purchases_flutter 10.3.0`).
> Sources of truth: **Tariq's official backend doc (2026-06-30)** + last session's exploration report + verified RC SDK surface.
> This revision resolved every `⚠️VERIFY` marker from commit `625f90a` against the authoritative doc — see §2.

---

## 1. Overview, scope, non-scope

### Goal
Turn the fully-built paywall UI (`packages_screen.dart`, 579 lines) from a `coming_soon` toast into a real store purchase: select pricing → RevenueCat purchase → webhook grants entitlement → refresh `/current`. Plus discount-code entry, free-tier path, and restore purchases.

### In scope
- **Data prep:** parse `appleProductId` / `googleProductId` **and `isFree`** onto the pricing/plan model + entity (the blocker); retire the obsolete `[PLANS_DEBUG]` log; rescope `SubscribeUseCase` to free-tier-only.
- **Purchase orchestration:** a `PurchaseRepository` over `RevenueCatService` (offering→package lookup by product id, purchase, error classification via `PurchasesErrorHelper`, restore).
- **Discount code (full, both platforms):** input widget + `POST /subscriptions/validate-code` + **real** iOS promotional-offer (`PromotionalOffer`) and **real** Android offer (`PurchaseParams.subscriptionOption`) application. Endpoint is live per doc — no network stub.
- **Free tier:** `isFree` / price 0 pricing → `POST /subscribe` path, no RC.
- **Cross-cubit:** on paid purchase success → `CurrentSubscriptionCubit.refresh(force: true)` (webhook is SoT) → pop paywall.
- **Same-tier re-purchase:** block + route to `SubscriptionDetailsScreen` (اشتراكي).
- **Restore purchases:** row in the user settings hub (`profile_screen.dart`), not the paywall app bar.
- **`packages_screen.dart` refactor** (Commit 5): extract `paywall_hero_widget.dart`, `plan_selection_widget.dart`, `pricing_row_widget.dart`, `sticky_cta_widget.dart`; the screen becomes a thin coordinator. Each < 200 lines.
- **Localization:** every new string (ar + en) + one error string per `PurchasesErrorHelper` category.

### Non-scope (explicit)
- **iOS purchases are LOCKED, not just untestable (Q-B).** The iOS `PromotionalOffer` / purchase code stays in the repo for later, but every iOS purchase entry point is disabled at the UI + guarded in the cubit, so nothing iOS-purchase runs this cycle. App Store products are Missing Metadata and iOS offers aren't created yet (§7). **Android is fully live + testable** (3 subs + 30 offers active — §7).
- No RC dashboard / store-console work (Track A — done, §7).
- No webhook / backend work (Tariq's endpoints are ready per his doc).
- No change to the plans/current caching layer (shipped) or the paywall *gate sheet* copy (`paywall_bottom_sheet.dart`).
- The legacy `GET /discount-codes/{code}/validate` endpoint (superseded by `validate-code`) — not used.
- `rc_product_map.dart` — **confirmed does not exist** (grep clean); nothing to delete.
- The 401→login interceptor is a **pre-existing infra gap** (tracked in HANDOFF); this plan relies on it but does not build it.

### Key architectural decisions (locked by your answers + the doc)
- **iOS purchases are FULLY LOCKED this cycle (Q-B).** Not just discounts — every purchase path is disabled on iOS until Mac + Apple offers + Missing-Metadata are resolved. On iOS: plans render read-only, the CTA is disabled with a "coming soon" message, and the discount field is **hidden entirely**. Restore stays enabled (non-purchase). Gated at the UI (primary) **and** defensively in the cubit/repo (no accidental iOS transaction). Android is the only live purchase platform.
- **Post-purchase = trust RC entitlement locally + bounded `/current` reconcile + RC listener (Q-C).** RC `CustomerInfo.hasPremium` is the *instant* success signal (unlock immediately, no webhook wait); `/current` is reconciled with a **bounded background retry** (webhook lag 2–5 s) so plan/counter details + feature gates elsewhere converge without an indefinite spinner; an app-scoped RC `CustomerInfoUpdateListener` catches out-of-band entitlement changes. Full justification in Commit 4. The client never `POST /subscribe` for a paid purchase — the webhook grants it; `/subscribe` is **free-tier-only** and *rejects* paid tiers (§2.6).
- **Upgrades/downgrades ALLOWED (Q-A).** Block **only** re-purchase of the *identical* `productId`. Any different product (basic→vip, monthly→3month) is allowed; on Android we pass `StoreProductChangeInfo(oldProductId, replacementMode: withTimeProration)` so Play prorates (verified SDK path, §2.12). Same-identical-product tap → block dialog → route to اشتراكي.
- **Product lookup key = `pricing.googleProductId`** on Android / `appleProductId` on iOS → matched against `package.storeProduct.identifier` in offering `default` (confirmed §2.2, §7).
- **Premium SoT stays `/current`** (`CurrentSubscriptionCubit.hasActiveSubscription`) for plan/counter details; RC entitlement is the instant unlock signal.
- **Errors mapped by code, not message** — HTTP: `errorCode` string (§2.9); store: `PurchasesErrorCode` via `PurchasesErrorHelper`.

---

## 2. Verification pass — results vs Tariq's doc

Legend: ✅ CONFIRMED · 🔧 CORRECTED · ❓ UNRESOLVED (→ escalated to §5).

| # | Item | Verdict | Detail |
|---|------|---------|--------|
| 2.1 | **Envelope per endpoint** | ✅ | Per doc §1 table: `plans`, `current`, `validate-code`, legacy `discount-codes/.../validate` = **RAW**; `subscribe` = **wrapped `ApiResponse`**. Matches our datasource (`getRaw` for plans/current, `postRaw`+`body['data']` for subscribe). |
| 2.2 | **Product-id field names** | ✅ | `appleProductId` + `googleProductId` per pricing (both present, nullable). Confirmed in doc's plans example. |
| 2.3 | **`isFree` flag** | 🔧 | **NEW gap found.** Doc: free plan = `isFree:true` + `pricings[].price=0` + product ids `null`. Our `SubscriptionPlanModel`/entity **don't parse `isFree`**. Added to Commit 1 (needed for free-tier routing). |
| 2.4 | **`validate-code` REQUEST body** | 🔧 | Was assumed `{code, pricingId}`. **Corrected** per doc: `{ "code", "productId", "platform" }` — `productId` = the pricing's platform store id, `platform` = `"android"`/`"ios"` (lowercase). |
| 2.5 | **`validate-code` RESPONSE** | 🔧 | Plan model omitted fields. **Corrected** per doc: `{ valid:bool, discountPercent:int, offerId:String?, signature:String?, keyId:String?, nonce:String?, timestampMs:int?, message:String? }`. `timestampMs` is int ms. Edge: valid code but Apple signature unconfigured → `valid:true, signature:null, message:"توقيع آبل غير مُهيّأ بعد"`. |
| 2.6 | **`subscribe` scope** | ✅ | Free-tier-only confirmed; paid (>0) rejected here with status:0 «هذا الاشتراك مدفوع ويُفعَّل عبر المتجر»; free-once «الباقة المجانية متاحة مرة واحدة فقط». These are **message-only (no distinct errorCode)** — our datasource already surfaces `body['message']`. |
| 2.7 | **`/current` semantics** | ✅ | Null body = not premium (raw, no wrapper). Unlimited sentinel = `2147483647` (int.MaxValue). Our gate uses `isCurrentlyActive` (expiresAt>now) — consistent. |
| 2.8 | **Auth 401 / no refresh** | ✅ | `Authorization: Bearer`, 7-day, no refresh, 401→login, logout=delete-local. (Interceptor is the pre-existing infra gap.) |
| 2.9 | **Error mapping key** | ✅ | Map on `errorCode` string, not message (doc §4). Stable codes listed. Store errors via `PurchasesErrorHelper`. Caveat: subscribe free-path rejections are message-only (2.6). |
| 2.10 | **Enum case handling** | ✅ | Enums returned as strings; sending is case-insensitive. We send `platform` lowercase per doc example. |
| 2.11 | **Image URL construction** | ✅ | Relative → absolute + Bearer (doc §5). Not relevant to paywall (plan `icon` is emoji/URL, already handled). |
| 2.12 | **RC SDK offer API** (was Open Q3) | 🔧→✅ | Verified `purchases_flutter 10.3.0`: **iOS** → `PromotionalOffer(offerId, keyId, nonce, signature, timestampMs)` + `PurchaseParams.package(pkg, promotionalOffer:)`. **Android** → find `SubscriptionOption` on `pkg.storeProduct.subscriptionOptions` matching `offerId` + `PurchaseParams.subscriptionOption(option)`. **⇒ Android discount is buildable for real (no stub).** Only the exact `SubscriptionOption.id`↔`offerId` string format needs a one-line device log to confirm (§5 Q-D). |

**Net:** 7 CONFIRMED, 5 CORRECTED, 0 blocking-unresolved. No endpoint is missing; no structural rework needed. The 7-commit shape stands.

---

## 3. Commit sequence (atomic, each shippable)

| # | Commit | Ships? | Touches UI? |
|---|--------|--------|-------------|
| 1 | Data prep: product-id + `isFree` fields · retire debug log · rescope SubscribeUseCase | ✅ (no behaviour change) | no |
| 2 | `validate-code` plumbing (endpoint, DTOs, datasource, repo, usecase) | ✅ (dormant) | no |
| 3 | Purchase orchestration layer (PurchaseRepository + failures + usecases) | ✅ (dormant) | no |
| 4 | `PackagePurchaseCubit` + DI wiring | ✅ (dormant) | no |
| 5 | Refactor `packages_screen` into 4 widgets **and** wire CTA live | ✅ **the flip** | yes |
| 6 | Discount-code input widget (iOS + Android real) | ✅ | yes |
| 7 | Restore purchases (settings row) | ✅ | yes |

Commits 1–4 leave the CTA on `coming_soon` (harmless). Commit 5 is the go-live flip.

---

## 4. Per-commit detail (files, ~lines, gates)

**Global gates on every commit:** `flutter analyze lib/features/subscriptions` (+ any core file touched) clean · legacy-grep ZERO on touched DS widgets (no `Color(0x..)`, Material colors/widgets, `AppColors`/`AppTextStyles`/`AppDimens`/`CustomButton`/`AppTextFormField`) · every file < 200 lines · every function < 30 lines · `AppLogger` only · ask before staging `qeran_colors.dart` / `docs/` / `web/`.

### Commit 1 — Data prep (the blocker)
- `data/models/subscription_pricing_model.dart` (+~6) — parse `appleProductId` / `googleProductId` (`String?`) in `fromJson` + ctor + `toEntity`.
- `domain/entities/subscription_pricing.dart` (+~10) — add both fields + `props`; add helper `String? productId({required bool isIOS})`.
- `data/models/subscription_plan_model.dart` (+~3) — parse `isFree` (`bool`, default false). *(§2.3)*
- `domain/entities/subscription_plan.dart` (+~4) — add `isFree` + `props`; add `bool get isFreeTier => isFree` convenience (or reuse directly).
- `presentation/blocs/plans/subscription_plans_cubit.dart` (−~22) — delete `_logPlanIdentifiersOnce`/`_loggedIdsOnce`/call site/`TODO(payments-mapping)` + orphaned `AppLogger` import.
- `domain/usecases/subscribe_usecase.dart` (~2) — doc comment → *"Free-tier subscription (`isFree` / final price 0 / 100% code) only. Paid subscriptions activate via RevenueCat + webhook, NOT this endpoint (backend rejects paid here)."* Remove `TODO(payments-1b)`.
- **Est:** 6 files, ~55 lines net. **Gate:** analyze clean; all files < 200.

### Commit 2 — `validate-code` plumbing (no UI)
- `core/api/end_points.dart` (+~2) — `static const String validateCode = "subscriptions/validate-code";`.
- **New** `data/models/validate_code_response_model.dart` (~55) — parses **all** fields (§2.5): `valid`, `discountPercent`, `offerId?`, `signature?`, `keyId?`, `nonce?`, `timestampMs?`, `message?`. RAW (no envelope).
- **New** `domain/entities/validated_offer.dart` (~40) — `valid`, `discountPercent`, `offerId?`, iOS params, `message?`; helpers `bool get isValid`, `bool get hasIosSignature` (signature+keyId+nonce+timestampMs all non-null).
- `data/datasources/subscriptions_remote_datasource.dart` (+~22) — `validateCode({required String code, required String productId, required String platform})` → `postRaw`, parses RAW response. Sends `platform` lowercase (§2.10).
- `data/repositories/subscriptions_repository_impl.dart` (+~10) + `domain/repositories/subscriptions_repository.dart` (+~4) — `Future<Either<Failure, ValidatedOffer>> validateCode(...)` via `executeApiCall`.
- **New** `domain/usecases/validate_code_usecase.dart` (~20) — resolves `productId` from the selected pricing per platform, passes through.
- **Est:** 2 new + 4 edits, ~150 lines. **Gate:** analyze; new files < 200.

### Commit 3 — Purchase orchestration layer (no UI)
- **New** `domain/repositories/purchase_repository.dart` (~24) — `Future<Either<Failure,bool>> purchase({required String productId, ValidatedOffer? offer, String? oldProductId})` (bool = hasPremium; `oldProductId` = the current active product for an upgrade) + `Future<Either<Failure,bool>> restore()`.
- **New** `data/repositories/purchase_repository_impl.dart` (~130) — wraps `RevenueCatService`: `getOfferings()` → find `Package` in offering `default` where `storeProduct.identifier == productId`. Builds `PurchaseParams`:
  - **no offer** → `PurchaseParams.package(pkg, productChangeInfo:)`.
  - **iOS + offer.hasIosSignature** → `PromotionalOffer(offer.offerId!, offer.keyId!, offer.nonce!, offer.signature!, offer.timestampMs!)` → `PurchaseParams.package(pkg, promotionalOffer:)`. **(iOS is UI-locked this cycle — this path is dormant; Q-B.)** *(§2.12)*
  - **Android + offer.offerId** → match `pkg.storeProduct.subscriptionOptions` by `offerId` → `PurchaseParams.subscriptionOption(option, productChangeInfo:)`; fall back to base package if unmatched (log warn). *(§2.12, §5 Q-D)*
  - **upgrade (Android, `oldProductId != null && != productId`)** → `productChangeInfo: StoreProductChangeInfo(oldProductId, replacementMode: StoreReplacementMode.withTimeProration)` on the params above. *(Q-A, verified SDK)*
  - classify `PlatformException` via `PurchasesErrorHelper.getErrorCode` → typed failures; return `hasPremium(info)`.
  - Split `_resolvePurchaseParams` / `_classifyError` into a helper file to stay < 200.
- `core/errors/errors.dart` (+~24) — `PurchaseCancelledFailure`, `StoreUnavailableFailure`, `AlreadyOwnedFailure`, `PurchasePendingFailure` (each locale-keyed). Reuse `OfflineFailure` for store-network.
- **New** `domain/usecases/purchase_package_usecase.dart` (~18) + `domain/usecases/restore_purchases_usecase.dart` (~15).
- **Est:** 4 new + 1 edit, ~190 lines. **Gate:** `flutter analyze lib/features/subscriptions lib/core/errors`; impl < 200 (split if needed).

### Commit 4 — `PackagePurchaseCubit` + `/current` reconcile + DI (no screen change)

**Post-purchase flow (Q-C) — recommendation & justification.** RC's local `CustomerInfo` is the authoritative *entitlement* cache (the SDK persists + updates it), while backend `/current` is our SoT for *plan details + counters*. So:
1. On paid success, `PurchasePackageUseCase` returns `hasPremium` from the post-purchase `CustomerInfo` — an **instant, local, correct** unlock signal. Emit `PurchaseSuccess` immediately → **no spinner waits on the webhook**.
2. Then call `currentSub.reconcileAfterPurchase()` — a **bounded** background retry on `/current` (force-refresh at 0 s; if still not-active, retry at ~2 s and ~4 s; stop as soon as active; **max 3 attempts ≈ 6 s, then give up silently**). This converges plan/counter details + every feature gate to the backend truth despite webhook lag (2–5 s), with **no indefinite spinner** (UI already succeeded in step 1).
3. Register an app-scoped `Purchases.addCustomerInfoUpdateListener` (in `CurrentSubscriptionCubit` on hydrate) → any out-of-band entitlement change (webhook catch-up, cross-device, restore) triggers a single `refresh(force:true)`, keeping gates consistent outside the purchase flow too.

This trusts the fastest-correct source for UX (RC entitlement), reconciles the detail SoT with bounds, and self-heals via the listener. Free-tier success uses the existing `onSubscribed(...)` (the `/subscribe` response *is* a `CurrentSubscription`, so no reconcile needed).

- **New** `presentation/blocs/purchase/package_purchase_state.dart` (~60) — `PurchaseIdle`, `PurchaseValidatingCode`, `PurchaseCodeApplied(offer)`, `PurchaseCodeRejected(msg)`, `PurchaseInProgress`, `PurchaseSuccess`, `PurchaseCancelled`, `PurchaseFailure(reason)`, `PurchaseLockedIos`.
- **New** `presentation/blocs/purchase/package_purchase_cubit.dart` (~150):
  - ctor takes `CurrentSubscriptionCubit` (app-scoped singleton) + the 3 usecases + `bool isIOS = Platform.isIOS` (injectable for tests).
  - **iOS defensive guard:** `purchase(...)` on iOS → emit `PurchaseLockedIos`, no store call (primary gate is the UI in Commit 5; this prevents any accidental invocation). Q-B.
  - `purchase(SubscriptionPlan plan, SubscriptionPricing pricing)`: **free** (`plan.isFree || pricing.price == 0`) → `SubscribeUseCase` → on Right `currentSub.onSubscribed(...)` + `PurchaseSuccess`; **paid** → `PurchasePackageUseCase(productId: pricing.productId(isIOS:false)!, offer: _appliedOffer, oldProductId: _currentActiveProductId)`.
  - `_currentActiveProductId` = `currentSub.subscription?.pricing.googleProductId` (drives upgrade proration; Q-A). Same-identical-product is blocked upstream in the CTA, not here.
  - paid success → emit `PurchaseSuccess` **first**, then fire-and-forget `currentSub.reconcileAfterPurchase()`.
  - `validateCode(code, plan, pricing)` → `ValidateCodeUseCase`; on `valid` store `_appliedOffer` + `PurchaseCodeApplied(discountPercent)`; else `PurchaseCodeRejected(message)`. `clearCode()` resets.
  - `PurchaseCancelledFailure`→`PurchaseCancelled` (silent); others→`PurchaseFailure(localized msg)`.
  - split code-validation into a mixin file if body > 200.
- `presentation/blocs/current/current_subscription_cubit.dart` (+~24) — add `Future<void> reconcileAfterPurchase({int attempts = 3, Duration gap = const Duration(seconds: 2)})` (bounded retry loop, `isClosed`-safe, stops when `hasActiveSubscription`) + register/dispose the RC `CustomerInfoUpdateListener` (guarded so a payment-SDK hiccup never breaks the cubit). Stays < 200.
- `di/subscriptions_injection.dart` (+~12) — register `PurchaseRepository` (lazySingleton; `sl<RevenueCatService>()` already global), `PurchasePackageUseCase`, `RestorePurchasesUseCase`, `ValidateCodeUseCase`; `PackagePurchaseCubit` **factory** receiving `sl<CurrentSubscriptionCubit>()`.
- **Est:** 2 new + 2 edits, ~210 lines total (each file < 200). **Gate:** analyze; each file < 200.

### Commit 5 — Refactor `packages_screen` + wire CTA live 🔴 the flip
Refactor first, then wire — one commit so the screen lands at < 200 lines *and* live together.
- **New** `presentation/widgets/paywall_hero_widget.dart` (~90) — extracted hero (`QeranPremiumBanner` block).
- **New** `presentation/widgets/plan_selection_widget.dart` (~150) — extracted `_PlanTabs` + plan card/feature list.
- **New** `presentation/widgets/pricing_row_widget.dart` (~130) — extracted `_PricingRows`/`_PricingRow`.
- **New** `presentation/widgets/sticky_cta_widget.dart` (~150) — CTA + `BlocConsumer<PackagePurchaseCubit>`:
  - **iOS lockdown (Q-B):** if `Platform.isIOS` → CTA disabled + inline `subscriptions_ios_coming_soon` message (plans still render read-only). No purchase path reachable on iOS.
  - Android: in-progress spinner/disabled; success → pop (+ optional confirm); cancelled → silent; failure → `AppSnackBar` error.
  - **same-product guard (Q-A):** block **only** when the selected pricing's `googleProductId == currentSub.subscription?.pricing.googleProductId` (identical product) → block dialog → `RouteNames.subscriptionDetails`. Different product (upgrade/downgrade) proceeds → proration handled in the repo.
  - free-tier CTA label variant.
- `presentation/screens/packages_screen.dart` (→ ~150) — thin coordinator: `BlocProvider<PackagePurchaseCubit>` + `SubscriptionPlansCubit`, composes the 4 widgets, replaces `_openPurchase` toast (old lines 204–211).
- `assets/translations/{ar,en}.json` — purchase state + error strings (§Localization). Regenerate `locale_keys.g.dart`.
- **Est:** 4 new + 1 rewrite + 2 json + generated. **Gate:** **every file < 200** (this is the point of the refactor); legacy-grep ZERO on all 5 widget files; analyze clean; RTL+LTR.

### Commit 6 — Discount-code input widget (Android live; hidden on iOS)
- **New** `presentation/widgets/discount_code_field.dart` (~150) — DS-only field (tokens, no `AppTextFormField`), states: empty→apply · validating (spinner) · applied (gold check + `discountPercent` label + clear) · rejected (danger `message`). Bidirectional. Calls `cubit.validateCode`/`clearCode`. The applied offer flows through the cubit into the purchase (Android `subscriptionOption` per §2.12; iOS promo path exists but is dormant).
- Coordinator (+~4) — mount the field above the CTA **only when `!Platform.isIOS`** (Q-B: hidden entirely on iOS to avoid confusion).
- `assets/translations/{ar,en}.json` — code labels/errors. Regenerate.
- **Est:** 1 new + 1 edit + json. **Gate:** legacy-grep ZERO; new file < 200. Android tested for real (offers active, §7); iOS field not shown.

### Commit 7 — Restore purchases (settings)
- `presentation/screens/profile_screen.dart` (+~14) — a `_SettingsRow` (restore icon) after the subscription row → runs `RestorePurchasesUseCase` (inline `showDialog` progress, or a ~50-line `RestorePurchasesCubit` if you prefer testable state) → restored-premium → `currentSub.refresh(force:true)` + success toast; nothing-found → info toast. Both localized.
- **New (optional)** `presentation/blocs/restore/restore_purchases_cubit.dart` (~50) if inline is too heavy.
- `assets/translations/{ar,en}.json` — restore row + results. Regenerate.
- **Est:** 1 edit (+opt 1 new) + json. **Gate:** analyze; legacy-grep ZERO; profile_screen stays functional.

### Localization keys to add (ar + en)
`subscriptions_ios_coming_soon` (AR: «الشراء عبر iPhone قريباً. جرّب من جهاز Android حالياً.» · EN: "Purchases on iPhone coming soon. Please use an Android device for now."), `subscriptions_purchase_in_progress`, `subscriptions_purchase_success`, `subscriptions_purchase_cancelled`, `subscriptions_purchase_failed_generic`, `subscriptions_purchase_store_unavailable`, `subscriptions_purchase_already_owned`, `subscriptions_purchase_pending`, `subscriptions_same_product_block_title/body`, `subscriptions_free_cta`, `subscriptions_code_hint`, `subscriptions_code_apply`, `subscriptions_code_applied` (with `%` arg), `subscriptions_code_clear`, `subscriptions_restore_row`, `subscriptions_restore_success`, `subscriptions_restore_none`. (Rejection text for a bad code comes from the server `message` per §2.5 — no client key.)

---

## 5. Questions for Anas — all resolved (2026-07-02)

- **Q-A — Upgrade path → RESOLVED: ALLOW.** Allow any different-product change (basic→vip, monthly→3month); Play prorates via `StoreProductChangeInfo(oldProductId, replacementMode: withTimeProration)`. **Block only re-purchase of the identical `productId`** → route to اشتراكي. Wired now (Commit 3 repo + Commit 5 CTA guard).
- **Q-B — iOS → RESOLVED: FULLY LOCKED.** All iOS purchase paths disabled this cycle (not just discounts). Plans render read-only; CTA disabled + `subscriptions_ios_coming_soon` message; discount field hidden entirely on iOS; restore stays enabled. Gated at UI + defensively in the cubit. Reflected in Commits 3/4/5/6.
- **Q-C — Post-purchase → RESOLVED: RC-entitlement + bounded `/current` reconcile + RC listener.** Full design & justification in Commit 4. Instant unlock from RC `hasPremium`, bounded background retry on `/current` for webhook lag (≤3 attempts ≈6 s, no indefinite spinner), app-scoped `CustomerInfoUpdateListener` for out-of-band updates.
- **Q-D — (verify-on-device, not a blocker)** The exact `SubscriptionOption.id` ↔ backend `offerId` string format on Google Play → one debug log during Commit 6 device testing to confirm the match rule (`==` vs `endsWith`/`contains`). I'll surface the real value and confirm before finalizing Commit 6.

---

## 6. Verification & rollback

### 6a. Device tests per commit
- **C1:** analyze clean; app launches; plans still render (no regression); `[PLANS_DEBUG]` gone; `isFree` parsed (log a plan's `isFree` once to confirm). No behaviour change.
- **C2:** analyze; app launches. Dormant. Optional throwaway call logs a real `ValidatedOffer` (valid + invalid code) to confirm request/response shapes against the live endpoint.
- **C3 / C4:** analyze; app launches; dormant. C4 optional mocktail test (free routes to SubscribeUseCase; paid to PurchasePackageUseCase; cancel→`PurchaseCancelled`; code applied stored).
- **C5 (Android, real device, Play internal-test track):**
  1. Non-subscriber taps a **paid** plan CTA → Play sheet → complete → **instant success + pop** (from RC entitlement); `/current` converges within a few seconds via `reconcileAfterPurchase` → gated actions elsewhere unlock without a manual refresh.
  2. Cancel the Play sheet → silent return, CTA re-enabled, no error toast.
  3. **Free-tier** plan (if backend exposes one) → no Play sheet → `/subscribe` → active; second attempt → «الباقة المجانية متاحة مرة واحدة فقط».
  4. **Upgrade (Q-A):** subscribed to basic, tap **vip** (different product) → Play proration sheet → success. Tap the **identical** product → block dialog → routes to اشتراكي.
  5. Airplane mode → CTA → offline failure toast, no crash.
  6. RTL (ar) + LTR (en): CTA, spinner, dialogs mirror correctly.
  7. **Every extracted widget file < 200 lines** (`packages_screen` refactor goal met).
- **C5 (iOS build — lockdown check, Q-B):** plans render read-only; CTA disabled + `subscriptions_ios_coming_soon` message; **no** discount field; tapping nothing triggers a purchase; restore (C7) still works. RTL+LTR.
- **C6 (Android):** invalid code → server `message` shown; valid code → applied state + `discountPercent`; the offer reaches the purchase and the Play sheet shows the **discounted** price (confirms Android offer path + Q-D match rule). Clear works. RTL+LTR.
- **C7 (Android):** Settings → Restore: account with a prior purchase → restored + premium reflected; fresh account → "nothing to restore". RTL+LTR.
- **iOS across C5–C7:** purchase paths **locked** (Q-B) — verify the lockdown UI only; restore may be smoke-tested if a sandbox account exists. Each commit message states iOS purchase is locked/untested.

### 6b. Rollback strategy per commit
Every commit is atomic and independently `git revert`-able; commits 1–4 are dormant (no UI entry) so reverting them can't break a shipped path.
- **C1:** additive fields + a log deletion → revert restores prior model/entity; no persisted state. Safe.
- **C2/C3/C4:** dormant layers → revert removes unused code; nothing references them until C5. Safe.
- **C5 (the flip):** the only behaviour-changing commit. Revert → CTA returns to the `coming_soon` toast (current shipped state) and the screen to its pre-refactor form. Keep it a single focused commit so revert is surgical.
- **C6 / C7:** revert removes the discount field / restore row respectively; purchase keeps working without them. Independent.
- **Kill-switch (no client push):** because premium is `/current`-driven, disabling the RC offering / server-side stops purchases; the CTA then surfaces "store unavailable" via the existing failure path.

---

## 7. Setup status (as of this session)
- **Google Play:** 3 subscriptions **active** (`qeran_basic_monthly`, `qeran_vip_monthly`, `qeran_vip_3month`) + **30 offers active** (10 per base plan: 5/10/15/20/25/30/40/50/70/90 %). ⇒ Android purchase **and** discount are testable for real.
- **RevenueCat:** offering `default` with 3 packages (`basic_monthly`, `vip_monthly`, `vip_3month`), each attached to its matching Android product; entitlement `premium`. SDK `purchases_flutter 10.3.0` (offer API verified — §2.12).
- **iOS:** 3 subscriptions in **Missing Metadata**; **iOS offers NOT created yet** (deferred until Mac + a paywall screenshot exist). ⇒ **iOS purchases are fully LOCKED this cycle (Q-B)** — UI-disabled + cubit-guarded; the iOS `PromotionalOffer` code exists but is dormant.
- **Backend:** Tariq's authoritative doc landed (2026-06-30). `validate-code` and all payment endpoints ready per doc; RevenueCat webhook built server-side (deployment confirmation is on whoever deploys the API).

---

## Ready to build?
This plan writes no code. **All §5 decisions (Q-A/B/C) are resolved and folded in** (Q-D is a device-verify during C6, not a blocker). On approval I start at **Commit 1** and STOP after each commit for your review + the device test above, committing + pushing per your per-piece rule.
