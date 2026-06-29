import 'dart:io' show Platform;

/// RevenueCat SDK keys, resolved at build time.
///
/// RevenueCat's *SDK* keys are PUBLIC (designed to ship in the client) — they
/// are not secrets, so a const default is safe. The truly secret key (server
/// webhook validation) lives only with the backend and never enters the app.
///
/// Keys are overridable per platform via `--dart-define` so release builds
/// inject production keys without committing them:
///   flutter build appbundle \
///     --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
///     --dart-define=REVENUECAT_IOS_KEY=appl_xxx
/// With no define, the shared TEST key is used (friction-free local dev).
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Shared sandbox/test key (RevenueCat project "Qeran"). Public by design.
  static const String _testKey = 'test_HqEqSHfkEMpiQInqAdGjivICcdd';

  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: _testKey,
  );

  static const String iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: _testKey,
  );

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
