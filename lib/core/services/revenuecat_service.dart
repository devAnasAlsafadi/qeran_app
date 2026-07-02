import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../app_logger.dart';
import '../config/revenuecat_config.dart';

/// Thin wrapper around the RevenueCat SDK (P1 — init + identity only).
///
/// Holds no purchase/paywall logic yet. [configure] boots the SDK anonymously
/// at launch; [logIn]/[logOut] tie RevenueCat's `appUserID` to the backend
/// user id so server-side webhooks can map entitlements to the right account.
/// Every call is defensive — a payment-SDK failure must never break launch or
/// the session flow.
class RevenueCatService {
  bool _configured = false;
  bool get isConfigured => _configured;

  /// One-time SDK configuration. Safe to call more than once. Anonymous —
  /// user identity is attached later via [logIn].
  Future<void> configure() async {
    if (_configured) return;
    final apiKey = RevenueCatConfig.apiKeyForPlatform();
    if (apiKey.isEmpty) {
      AppLogger.warning('RevenueCat API key empty — skipping configure',
          tag: 'RC');
      return;
    }
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
    AppLogger.info('RevenueCat configured', tag: 'RC');
  }

  /// Aliases the RevenueCat user to the backend user id (== `appUserID`), so
  /// purchases and webhook events resolve to the same account. No-op until
  /// [configure] has run or when [appUserId] is empty.
  Future<void> logIn(String appUserId) async {
    if (!_configured || appUserId.isEmpty) return;
    try {
      await Purchases.logIn(appUserId);
      AppLogger.info('RevenueCat logIn ok', tag: 'RC');
    } catch (e, s) {
      AppLogger.error('RevenueCat logIn failed', error: e, stack: s, tag: 'RC');
    }
  }

  /// Resets RevenueCat back to an anonymous user on sign-out. `Purchases.logOut`
  /// throws if the user is already anonymous, so we guard on [isAnonymous].
  Future<void> logOut() async {
    if (!_configured) return;
    try {
      if (await Purchases.isAnonymous) return;
      await Purchases.logOut();
      AppLogger.info('RevenueCat logOut ok', tag: 'RC');
    } catch (e, s) {
      AppLogger.error('RevenueCat logOut failed',
          error: e, stack: s, tag: 'RC');
    }
  }

  /// Fetches the configured offerings (products grouped into packages).
  /// Defensive: returns null + logs on failure so a store hiccup degrades
  /// to a clear "store unavailable" message rather than a crash.
  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e, s) {
      AppLogger.error('RevenueCat getOfferings failed',
          error: e, stack: s, tag: 'RC');
      return null;
    }
  }

  /// Raw purchase with fully-built [params] (offer / product-change / promo).
  /// Intentionally NOT wrapped in try/catch — the [PlatformException] must
  /// propagate so the caller (PurchaseRepository) can classify cancel /
  /// network / already-owned via `PurchasesErrorHelper`. Returns the
  /// post-purchase [CustomerInfo], whose `entitlements` reflect new access.
  Future<CustomerInfo> purchase(PurchaseParams params) async {
    final result = await Purchases.purchase(params);
    return result.customerInfo;
  }

  /// Convenience for a plain package purchase (no offer / product change).
  /// Delegates to [purchase]; the [PlatformException] still propagates.
  Future<CustomerInfo> purchasePackage(Package package) =>
      purchase(PurchaseParams.package(package));

  /// True when [info] carries the premium entitlement as active.
  bool hasPremium(CustomerInfo info) => info.entitlements.active
      .containsKey(RevenueCatConfig.premiumEntitlementId);

  /// Current [CustomerInfo] (entitlement snapshot). Defensive: returns null +
  /// logs on failure so a status check degrades gracefully rather than throws.
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e, s) {
      AppLogger.error('RevenueCat getCustomerInfo failed',
          error: e, stack: s, tag: 'RC');
      return null;
    }
  }

  /// Restores prior purchases — recovers the entitlement after a reinstall
  /// or on a new device, and reconciles any client/RC desync. Defensive.
  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e, s) {
      AppLogger.error('RevenueCat restore failed',
          error: e, stack: s, tag: 'RC');
      return null;
    }
  }
}
