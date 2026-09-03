import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/widgets/app_lifecycle_privacy_shield.dart';

/// Shared fixtures for the privacy-shield suites, which are split in two:
/// behaviour every platform agrees on lives in
/// `app_lifecycle_privacy_shield_test.dart`, and the platform-specific
/// `inactive` matrix in `app_lifecycle_privacy_shield_platform_test.dart`.
///
/// ⚠️ Any test whose outcome depends on the platform MUST declare it with
/// `variant: TargetPlatformVariant.only(...)`. Two reasons. `flutter test`
/// reports `defaultTargetPlatform` as **android** by default (an assert in the
/// framework's `_platform_io.dart` keys off `FLUTTER_TEST`), so an undeclared
/// test silently exercises the android path only. And setting
/// `debugDefaultTargetPlatformOverride` by hand fails the run outright: the
/// binding asserts every foundation debug variable is unset when the test body
/// returns, which is BEFORE `addTearDown` callbacks fire. The variant's own
/// setUp/tearDown sit outside that check.

/// The concealing fill the shield paints — matched by colour so the child's own
/// widgets can never be mistaken for it.
Finder concealer() => find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == QeranColors.wine,
);

/// Mounts the shield over a child that paints nothing wine, so [concealer]
/// cannot match the content it is meant to be hiding.
Future<void> pumpShield(
  WidgetTester tester, {
  ValueListenable<bool>? suppression,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AppLifecyclePrivacyShield(
        suppression: suppression,
        child: const Text(
          'protected content',
          textDirection: TextDirection.rtl,
        ),
      ),
    ),
  );
}

Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
  tester.binding.handleAppLifecycleStateChanged(state);
  await tester.pump();
}
