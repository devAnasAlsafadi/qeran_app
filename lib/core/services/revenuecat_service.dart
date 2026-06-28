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
}
