import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/services/revenuecat_service.dart';

/// RevenueCat's native log is quiet outside debug (cleanup audit `19`,
/// run 11): errors only, no warnings with purchase details in the device log.
void main() {
  test('debug: everything', () {
    expect(RevenueCatService.logLevelFor(debug: true), LogLevel.debug);
  });

  test('release or profile: errors only', () {
    expect(RevenueCatService.logLevelFor(debug: false), LogLevel.error);
  });
}
