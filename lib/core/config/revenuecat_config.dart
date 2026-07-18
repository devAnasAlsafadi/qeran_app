import 'dart:io' show Platform;

/// RevenueCat SDK keys, resolved at build time.
///
/// RevenueCat's *SDK* keys are PUBLIC (designed to ship in the client) — they
/// are not secrets, so const defaults are safe. The truly secret key (server
/// webhook validation) lives only with the backend and never enters the app.
///
/// Resolution order per platform (highest priority first):
///   1. `--dart-define=REVENUECAT_ANDROID_KEY=...` / `REVENUECAT_IOS_KEY=...`
///      — lets CI (or a throwaway Test Store build) inject a key without
///      editing source.
///   2. Otherwise → the production store key (Google Play `goog_…` /
///      App Store `appl_…`), in **every** build mode.
///
/// Debug/profile deliberately use the real Google Play key too, so the SDK and
/// the dashboard's store offerings always match. The Test Store key is gone —
/// it raised "no Test Store products registered" on purchase because the
/// offerings are Google Play products, not Test Store products.
class RevenueCatConfig {
  RevenueCatConfig._();

  // Production RevenueCat SDK keys (confirmed via a completed on-device
  // purchase). RC SDK keys are public/safe to ship, but must be the
  // production keys or release builds hit the "Wrong API Key" dialog.
  static const String _androidProductionKey =
      'goog_xkSZqDIzAXLbUfxUYsqtBUkcIjJ';
  static const String _iosProductionKey = 'appl_udfePLhIiRlxsOEEPzkILqcHjLc';

  /// `--dart-define` overrides (empty when not passed). Highest priority so an
  /// explicit build-time key always wins over the mode default.
  static const String _androidDefine =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const String _iosDefine =
      String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// Android key: a `--dart-define` wins; otherwise the Google Play production
  /// key, in every build mode.
  static String get androidApiKey =>
      _androidDefine.isNotEmpty ? _androidDefine : _androidProductionKey;

  /// iOS key: same resolution as [androidApiKey] (App Store production key).
  static String get iosApiKey =>
      _iosDefine.isNotEmpty ? _iosDefine : _iosProductionKey;

  /// The RevenueCat entitlement that unlocks premium features. Created in
  /// the RC dashboard (Product catalog → Entitlements) and attached to all
  /// paid products. The app gates on "has this entitlement", not on which
  /// tier was bought.
  static const String premiumEntitlementId = 'premium';

  /// The key for the current platform. RevenueCat supports only iOS + Android;
  /// Android is the default for any other target.
  static String apiKeyForPlatform() =>
      (Platform.isIOS || Platform.isMacOS) ? iosApiKey : androidApiKey;
}
