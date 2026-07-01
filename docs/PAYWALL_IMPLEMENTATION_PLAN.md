# Paywall / Purchase Flow — Implementation Plan

> Status: **PLAN — awaiting approval. No code written.**
> Feature: `lib/features/subscriptions/` + RevenueCat (`lib/core/services/revenuecat_service.dart`).
> Source of truth: Tariq's backend doc + last session's 5-section exploration report.
> ⚠️ **Caveat on this plan's provenance:** the `[PASTE_TARIQ_DOC_HERE]` placeholder in the task came through **unfilled**. Every backend-shape claim below (envelope, `validate-code` response fields, errorCode names, free-tier rule) is reconstructed from the digest captured last session. **Verify each against the real doc before Commit 2+.** Points that depend on it are tagged `⚠️VERIFY`.

---

## 1. Overview, scope, non-scope

### Goal
Turn the fully-built paywall UI (`packages_screen.dart`, 579 lines) from a `coming_soon` toast into a real store purchase: select pricing → RevenueCat purchase → webhook grants entitlement → refresh `/current`. Plus discount-code entry, free-tier path, and restore purchases.

### In scope
- **Data prep:** parse `appleProductId` / `googleProductId` onto the pricing model + entity (the blocker); retire the obsolete `[PLANS_DEBUG]` log; rescope `SubscribeUseCase` to free-tier-only.
- **Purchase orchestration:** a `PurchaseRepository` over `RevenueCatService` (offering→package lookup by product id, purchase, error classification via `PurchasesErrorHelper`, restore).
- **Discount code:** input widget + `POST /subscriptions/validate-code` plumbing + iOS promotional-offer params. Network call **stubbed with `TODO(payments-3)`** if the endpoint isn't live — never fake success.
- **Free tier:** `isFree` (price 0) pricing → `POST /subscribe` path, no RC.
- **Cross-cubit:** on purchase success → `CurrentSubscriptionCubit.refresh(force: true)` (webhook is SoT) → pop paywall.
- **Same-tier re-purchase:** block + route to `SubscriptionDetailsScreen` (اشتراكي).
- **Restore purchases:** row in the user settings hub (`profile_screen.dart`), not the paywall app bar.
- **Localization:** every new string (ar + en) + one error string per `PurchasesErrorHelper` category.

### Non-scope (explicit)
- **iOS purchase is code-complete but UNTESTABLE this cycle** — App Store products are "Missing Metadata" (Q4 answer). We wire the iOS promotional-offer signature path but cannot run it. Android is the only testable target.
- No RC dashboard / store-console work (that's Track A, done: offering `default` + `basic_monthly` / `vip_monthly` / `vip_3month`).
- No webhook / backend work.
- No change to the plans/current caching layer (shipped) or the paywall *gate sheet* copy (`paywall_bottom_sheet.dart`) beyond leaving it intact.
- `rc_product_map.dart` — **confirmed does not exist** (grep clean); nothing to delete.

### Key architectural decisions (locked by your answers)
- **Post-paid-purchase = `/current` refresh only.** The client never `POST /subscribe` for a paid purchase — the webhook grants the entitlement. `/subscribe` is free-tier-only (Q2).
- **Product lookup key = `pricing.googleProductId`** on Android (per-platform; `appleProductId` on iOS) → matched against `package.storeProduct.identifier` in offering `default` (Q5).
- **Premium SoT stays `/current`** (`CurrentSubscriptionCubit.hasActiveSubscription`), consistent with the existing gate. RC `hasPremium` is used only as the immediate success signal to decide whether to refresh + pop.
- **Errors mapped by code, not message** (`errorCode` for HTTP; `PurchasesErrorCode` via `PurchasesErrorHelper` for the store). ⚠️VERIFY errorCode strings.

---

## 2. Commit sequence (atomic, each shippable)

| # | Commit | Ships? | Touches UI? |
|---|--------|--------|-------------|
| 1 | Data prep: product-id fields + retire debug log + rescope SubscribeUseCase | ✅ (no behaviour change) | no |
| 2 | `validate-code` plumbing (endpoint, DTOs, datasource[stub], repo, usecase) | ✅ (dormant) | no |
| 3 | Purchase orchestration layer (PurchaseRepository + failures + usecases) | ✅ (dormant) | no |
| 4 | `PackagePurchaseCubit` + DI wiring | ✅ (dormant) | no |
| 5 | Wire `packages_screen` CTA live (purchase + free-tier + same-tier block) | ✅ **the flip** | yes |
| 6 | Discount-code input widget | ✅ | yes |
| 7 | Restore purchases (settings row) | ✅ | yes |

Commits 1–4 leave the CTA still showing `coming_soon` (harmless). Commit 5 is the go-live flip. 6 and 7 are additive.

---

## 3. Per-commit detail (files, ~lines, gates)

**Global gates on every commit:** `flutter analyze lib/features/subscriptions` (+ any core file touched) clean · legacy-grep ZERO on touched DS widgets (no `Color(0x..)`, Material colors/widgets, `AppColors`/`AppTextStyles`/`AppDimens`/`CustomButton`/`AppTextFormField`) · every file < 200 lines · every function < 30 lines · `AppLogger` only · ask before staging `qeran_colors.dart` / `docs/` / `web/`.

### Commit 1 — Data prep (the blocker)
- `data/models/subscription_pricing_model.dart` (+~6) — parse `appleProductId` / `googleProductId` (nullable `String?`) in `fromJson` + ctor + `toEntity`. ⚠️VERIFY exact JSON field names.
- `domain/entities/subscription_pricing.dart` (+~10) — add both fields + `props`; add helper `String? productId({required bool isIOS})` returning the platform id.
- `presentation/blocs/plans/subscription_plans_cubit.dart` (−~22) — delete `_logPlanIdentifiersOnce` + `_loggedIdsOnce` + its call site + `TODO(payments-mapping)` + the now-unused `AppLogger` import if orphaned.
- `domain/usecases/subscribe_usecase.dart` (~2) — rewrite the doc comment: *"Free-tier subscription (`isFree` / price 0 / 100% discount) only. Paid subscriptions activate via RevenueCat + webhook, NOT this endpoint."* Remove the `TODO(payments-1b)`.
- **Est:** 4 files, ~40 lines net. **Gate:** analyze clean; model/entity still < 200.

### Commit 2 — `validate-code` plumbing (no UI)
- `core/api/end_points.dart` (+~2) — `static const String validateCode = "subscriptions/validate-code";`.
- **New** `data/models/validate_code_response_model.dart` (~45) — parses `{ offerId, signature?, keyId?, nonce?, timestampMs? }` (iOS promo params nullable). RAW response (no envelope). ⚠️VERIFY field names/shape.
- **New** `domain/entities/validated_offer.dart` (~30) — entity mirroring the above + `bool get hasIosSignature`.
- `data/datasources/subscriptions_remote_datasource.dart` (+~20) — `validateCode({required String code, required int pricingId})`. **If endpoint not live:** body throws `ServerException` behind `// TODO(payments-3): endpoint not yet deployed` — wired but honest, never fakes a valid offer. ⚠️VERIFY request body shape.
- `data/repositories/subscriptions_repository_impl.dart` (+~10) + `domain/repositories/subscriptions_repository.dart` (+~4) — `Future<Either<Failure, ValidatedOffer>> validateCode(...)` via `executeApiCall`.
- **New** `domain/usecases/validate_code_usecase.dart` (~18).
- **Est:** 2 new files + 4 edits, ~130 lines. **Gate:** analyze; new files < 200.

### Commit 3 — Purchase orchestration layer (no UI)
- **New** `domain/repositories/purchase_repository.dart` (~20) — `Future<Either<Failure,bool>> purchase({required String productId, ValidatedOffer? offer})` (bool = hasPremium) + `Future<Either<Failure,bool>> restore()`.
- **New** `data/repositories/purchase_repository_impl.dart` (~90) — wraps `RevenueCatService`: `getOfferings()` → find `Package` in offering `default` where `storeProduct.identifier == productId` → `purchasePackage(pkg[, iOS promo])` → `hasPremium(info)`. Classifies `PlatformException` via `PurchasesErrorHelper.getErrorCode` into typed failures. iOS promo params applied only when `offer.hasIosSignature && Platform.isIOS`. ⚠️VERIFY `purchases_flutter` v10 `PurchaseParams` promotional-offer API at implementation time.
- `core/errors/errors.dart` (+~24) — add `PurchaseCancelledFailure`, `StoreUnavailableFailure`, `AlreadyOwnedFailure`, `PurchasePendingFailure` (each with a locale-key message). Reuse `OfflineFailure` for network.
- **New** `domain/usecases/purchase_package_usecase.dart` (~18) — `call({required String productId, ValidatedOffer? offer})`.
- **New** `domain/usecases/restore_purchases_usecase.dart` (~15).
- **New** `core/services/revenuecat_service.dart` (+~6, optional) — overload `purchasePackage(Package, {ValidatedOffer? offer})` if the promo path needs it; else keep as-is and build `PurchaseParams` in the repo.
- **Est:** 4 new + 2 edits, ~180 lines. **Gate:** `flutter analyze lib/features/subscriptions lib/core/errors`; impl < 200 (split a `_classifyError` helper file if it grows).

### Commit 4 — `PackagePurchaseCubit` + DI (no screen change)
- **New** `presentation/blocs/purchase/package_purchase_state.dart` (~55) — `PurchaseIdle`, `PurchaseValidatingCode`, `PurchaseInProgress`, `PurchaseSuccess`, `PurchaseCancelled`, `PurchaseFailure(reason)`.
- **New** `presentation/blocs/purchase/package_purchase_cubit.dart` (~120) — orchestrates:
  - `purchase(SubscriptionPricing pricing)`: if `pricing.price == 0` → free-tier via `SubscribeUseCase` → on Right `currentSub.onSubscribed(...)`; else paid via `PurchasePackageUseCase(productId: pricing.productId(isIOS:...), offer: _validatedOffer)`.
  - on paid success → `currentSub.refresh(force: true)` (webhook SoT) → emit `PurchaseSuccess`.
  - `validateCode(code, pricingId)` → `ValidateCodeUseCase`; stores `_validatedOffer`; emits validating/valid/invalid. `clearCode()` resets.
  - maps `PurchaseCancelledFailure` → `PurchaseCancelled` (silent), others → `PurchaseFailure` with the failure's localized message.
  - takes `CurrentSubscriptionCubit` by reference (already an app-scoped singleton) for the cross-cubit refresh — no new coupling pattern.
  - If cubit body > 200 lines, split code-validation into a mixin file.
- `di/subscriptions_injection.dart` (+~12) — register `PurchaseRepository` (lazySingleton, `sl<RevenueCatService>()` is already global), `PurchasePackageUseCase`, `RestorePurchasesUseCase`, `ValidateCodeUseCase`; `PackagePurchaseCubit` as **factory** (screen-scoped) receiving `sl<CurrentSubscriptionCubit>()`.
- **Est:** 2 new + 1 edit, ~190 lines. **Gate:** analyze; cubit < 200.

### Commit 5 — Wire `packages_screen` CTA live 🔴 the flip
- `presentation/screens/packages_screen.dart` — replace `_openPurchase` toast (lines 204–211):
  - wrap the screen body in `BlocProvider<PackagePurchaseCubit>` + `BlocListener` (success → pop + optional confirmation; cancelled → nothing; failure → `AppSnackBar` error).
  - CTA: on tap, **same-tier guard first** — if `currentSub.hasActiveSubscription` and its plan == selected plan → `QeranConfirmDialog`/block dialog → route to `RouteNames.subscriptionDetails` (اشتراكي). Else `cubit.purchase(selectedPricing)`.
  - CTA shows in-progress (disabled + spinner) on `PurchaseInProgress`; free-tier pricing (`price == 0`) uses a distinct CTA label.
  - keep it backend-driven: no hardcoded names/prices/ids.
- `assets/translations/{ar,en}.json` — purchase state + error strings (see §Localization). Regenerate `locale_keys.g.dart`.
- **Est:** 1 screen edit (~+50/−8) + 2 json + generated. **Gate:** analyze; **packages_screen stays < 200?** — it's already **579 lines**. ⚠️ It exceeds the limit today (pre-existing). Adding purchase wiring must not grow the monolith: extract the CTA+listener into a private `_PurchaseCta` widget file and/or a `_PackagesBody` to keep new files < 200 and reduce the screen. Flag: the 200-line rule can't be *met* for the existing file without a refactor — propose a **scoped extraction** (see Open Q6), not a full rewrite.

### Commit 6 — Discount-code input widget
- **New** `presentation/widgets/discount_code_field.dart` (~140) — DS-only text field (no `AppTextFormField`; use the Qeran field widget / tokens), states: empty → apply; validating (spinner); valid (gold check + applied label + clear); invalid (danger message). Bidirectional. Calls `cubit.validateCode` / `cubit.clearCode`.
- `presentation/screens/packages_screen.dart` (+~4) — mount the field above the CTA; the validated offer flows through the cubit into the purchase.
- `assets/translations/{ar,en}.json` — code labels/errors. Regenerate.
- **Est:** 1 new + 1 edit + json. **Gate:** legacy-grep ZERO on the new field; new file < 200. ⚠️ Behind `TODO(payments-3)` if the endpoint is dark — the field will surface a clear "unavailable" state, never a fake success.

### Commit 7 — Restore purchases (settings)
- `presentation/screens/profile_screen.dart` (+~14) — add a `_SettingsRow` (restore icon) after the subscription row; on tap runs `RestorePurchasesUseCase` (via a tiny `showDialog` progress or a one-shot `RestorePurchasesCubit`, ~40 lines, if state is warranted) → on restored-premium `currentSub.refresh(force:true)` + success toast; on nothing-found an informational toast. Both outcomes localized.
- **New (optional)** `presentation/blocs/restore/restore_purchases_cubit.dart` (~50) if inline handling is too heavy for the screen.
- `assets/translations/{ar,en}.json` — restore row + result strings. Regenerate.
- **Est:** 1 edit (+opt 1 new) + json. **Gate:** analyze; profile_screen stays functional; legacy-grep ZERO.

---

## 4. Open questions (before / during implementation)

1. **⚠️VERIFY the whole Tariq-doc digest** — the source doc wasn't pasted. Confirm before Commit 2: exact JSON field names for `appleProductId`/`googleProductId` on each pricing; `validate-code` request body + response shape; whether `/validate-code` is deployed yet; the `errorCode` strings for subscribe/validate failures; the free-tier signal (`isFree` flag vs `price == 0`).
2. **Android discount mechanism.** `validate-code`'s iOS `signature/keyId/nonce/timestampMs` is clearly the StoreKit promotional-offer path. **What is the Android equivalent?** Google Play uses base-plan *offer tokens*, not signatures. Does the backend return an Android offer token / a different `googleProductId` for the discounted price, or is discount Android-only-later? This decides whether Commit 6's discount actually applies on our only testable platform, or is iOS-only-code + Android-stub.
3. **`purchases_flutter` v10 promotional-offer API.** Confirm the exact call to attach an iOS promo (`PurchaseParams` + `PromotionalOffer` / `getPromotionalOffer`) — the SDK surface changed across majors. Affects Commit 3's repo impl only.
4. **Same-tier vs any-active block.** You said "same-tier re-purchase → block + route to اشتراكي." If the user is on **basic** and taps **vip** (an upgrade), do we allow the purchase (Play handles proration) or also block/route? Assumed: **allow upgrade, block only identical plan.** Confirm.
5. **Webhook lag on success.** After RC reports `hasPremium == true`, `/current` may briefly still be stale (webhook is async). Plan: trust RC's `hasPremium` as the success signal, `refresh(force:true)` `/current`, and pop. If `/current` hasn't caught up, the details screen may lag one refresh. Acceptable for v1? (Alternative: optimistic `onSubscribed` needs a `CurrentSubscription` object we don't get from RC — so refresh is the honest path.)
6. **`packages_screen.dart` is 579 lines (pre-existing >200 violation).** Commit 5 can't satisfy "<200" for that file without touching it. Approve a **scoped extraction** (pull `_PurchaseCta` + `BlocListener` into their own files, and/or split the body) limited to what the wiring needs — or explicitly waive the rule for this legacy file this cycle?
7. **Restore state.** Inline (`showDialog` + await) vs a `RestorePurchasesCubit`? Recommend inline for v1 (one action, two outcomes) unless you want it testable in isolation.

---

## 5. Verification steps (device tests you run) per commit

- **C1:** `flutter analyze` clean; app launches; packages screen still renders plans (no regression); `[PLANS_DEBUG]` log gone from console. No behaviour change.
- **C2:** analyze clean; app launches. (Dormant — no user-visible path yet.) If endpoint live: a throwaway call logs a real offer; if dark: logs the `TODO(payments-3)` `ServerException`.
- **C3:** analyze clean; app launches. Dormant.
- **C4:** analyze clean; unit-testable cubit (optional mocktail test: free-tier routes to SubscribeUseCase; paid routes to PurchasePackageUseCase; cancel → `PurchaseCancelled`). Dormant in UI.
- **C5 (Android, real device, Play internal-test track, RC Test Store):**
  1. Non-subscriber taps a **paid** plan CTA → Play purchase sheet → complete → success → paywall pops → `/current` reflects active (may need the auto-refresh) → gated action unlocks.
  2. Cancel the Play sheet → returns silently to paywall, no error toast, CTA re-enabled.
  3. **Free-tier** plan (if backend exposes one) → no Play sheet → `/subscribe` → active.
  4. Already-subscribed, tap **same** plan → block dialog → routes to اشتراكي.
  5. Airplane mode → tap CTA → offline failure toast, no crash.
  6. RTL (ar) + LTR (en) both: CTA, spinner, dialogs mirror correctly.
- **C6 (Android):** enter invalid code → invalid state; valid code (or `TODO(payments-3)` unavailable state if dark) → applied/clear works; the applied offer is passed to purchase. RTL + LTR.
- **C7 (Android):** Settings → Restore: with a prior purchase on the account → restored + premium reflected; on a fresh account → "nothing to restore" info. RTL + LTR.
- **iOS across C5–C7:** build-only / code-review verification (products Missing Metadata → cannot transact). Note explicitly in each commit message that iOS is untested.

---

## 6. Rollback strategy per commit

Every commit is atomic and independently `git revert`-able; commits 1–4 are dormant so reverting any of them can't break a shipped user path.

- **C1:** pure additive fields + a log deletion → `git revert` restores prior model/entity; no data migration, no persisted state. Safe.
- **C2/C3/C4:** dormant layers (no UI entry) → revert removes unused code; nothing downstream references them until C5. Safe in any order after their own revert.
- **C5 (the flip):** the only behaviour-changing commit. Rollback = `git revert` → CTA returns to the `coming_soon` toast (the current shipped state). Because the gate is a single call site (`_openPurchase`), a revert is clean and low-risk. Keep C5 a **single focused commit** so revert is surgical.
- **C6:** revert removes the discount field; purchase (C5) keeps working without it. Independent.
- **C7:** revert removes the settings row; nothing else references restore. Independent.

Kill-switch alternative to a revert on C5 if a store issue appears post-release: because premium is `/current`-driven, disabling the offering server-side / RC dashboard stops purchases without a client push — the CTA would surface "store unavailable" via the existing failure path.

---

## Ready to build?
This plan writes no code. On approval I'll start at **Commit 1** and STOP after each commit for your review + the device test above, committing + pushing per your per-piece rule. Before Commit 2 I'll need the **real Tariq doc** (or your confirmation on the ⚠️VERIFY items + Open Qs 1–4).
