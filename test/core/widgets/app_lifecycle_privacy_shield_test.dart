import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/widgets/app_lifecycle_privacy_shield.dart';
import 'package:qeran/core/widgets/privacy_shield_suppression.dart';

import 'privacy_shield_harness.dart';

/// The shield sits above the Navigator, so it covers EVERY route. It exists to
/// keep a revealed photo, a chat, or profile data out of the app-switcher
/// snapshot. These tests pin that behaviour before it is touched, so any later
/// narrowing has to prove it left the protection intact.
///
/// Everything here is driven by `paused` / `hidden` — the states EVERY platform
/// treats as "not on screen any more", so these assertions hold whatever the
/// target platform is and say nothing about the transient `inactive` state.
/// That one is platform-specific and lives in
/// `app_lifecycle_privacy_shield_platform_test.dart`.
void main() {
  testWidgets('paints nothing over the app while it is in the foreground', (
    tester,
  ) async {
    await pumpShield(tester);

    expect(concealer(), findsNothing);
    expect(find.text('protected content'), findsOneWidget);
  });

  testWidgets('conceals once the app is backgrounded', (tester) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.paused);

    expect(concealer(), findsOneWidget);
  });

  testWidgets('conceals when hidden', (tester) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.hidden);

    expect(concealer(), findsOneWidget);
  });

  testWidgets('stays concealed across the whole backgrounding sequence', (
    tester,
  ) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.hidden);
    await lifecycle(tester, AppLifecycleState.paused);

    expect(concealer(), findsOneWidget);
  });

  testWidgets('lifts the fill once the app is back in the foreground', (
    tester,
  ) async {
    await pumpShield(tester);
    await lifecycle(tester, AppLifecycleState.paused);
    expect(concealer(), findsOneWidget);

    await lifecycle(tester, AppLifecycleState.resumed);

    expect(concealer(), findsNothing);
  });

  testWidgets('keeps the protected child mounted underneath', (tester) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.paused);

    // The fill covers; it must not REPLACE. Swapping the child out would drop
    // its state and reset whatever screen the user was on.
    expect(find.text('protected content'), findsOneWidget);
  });

  testWidgets('the fill covers the whole surface', (tester) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.paused);

    // A partial cover would leak the very content this exists to hide.
    expect(
      tester.getSize(concealer()),
      tester.getSize(find.byType(AppLifecyclePrivacyShield)),
    );
  });

  testWidgets('survives repeated notifications of the same state', (
    tester,
  ) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.paused);
    await lifecycle(tester, AppLifecycleState.paused);

    expect(concealer(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('standing down for a screen that asks', () {
    // Pinned to iOS: these exercise the shield through `inactive`, which only
    // iOS conceals on. Driving them unpinned would test the android path and
    // quietly stop covering the case the splash fix was written for — an iOS
    // permission alert raised over the splash.
    testWidgets('a suppressing screen keeps the fill off', (tester) async {
        final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpShield(tester, suppression: suppression);

      await lifecycle(tester, AppLifecycleState.inactive);

      // The splash case: the fill is the same wine as the canvas underneath, so
      // without this the screen looks correct and the animation is just gone.
      expect(concealer(), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a suppression that reads false changes nothing', (
      tester,
    ) async {
        final suppression = ValueNotifier<bool>(false);
      addTearDown(suppression.dispose);
      await pumpShield(tester, suppression: suppression);

      await lifecycle(tester, AppLifecycleState.inactive);

      expect(concealer(), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the fill returns the moment the screen stops asking', (
      tester,
    ) async {
        final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpShield(tester, suppression: suppression);
      await lifecycle(tester, AppLifecycleState.inactive);
      expect(concealer(), findsNothing);

      // The splash disposing while the app is already backgrounded: whatever
      // route comes next must be covered, with no second lifecycle event to
      // prompt it.
      suppression.value = false;
      await tester.pump();

      expect(concealer(), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('suppressing while resumed leaves nothing to hide', (
      tester,
    ) async {
      final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpShield(tester, suppression: suppression);

      expect(concealer(), findsNothing);
      expect(find.text('protected content'), findsOneWidget);
    });

    testWidgets('the protected child survives a suppressed background', (
      tester,
    ) async {
        final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpShield(tester, suppression: suppression);

      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.resumed);

      expect(find.text('protected content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('android suppression holds through a real background', (
      tester,
    ) async {
      // The android half of the splash stand-down. `inactive` is not a
      // concealing state there, so `paused` is the only way to prove the
      // suppression — not the platform default — is what keeps the fill off.
        final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpShield(tester, suppression: suppression);

      await lifecycle(tester, AppLifecycleState.paused);

      expect(concealer(), findsNothing);
      expect(find.text('protected content'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  group('the shared signal', () {
    testWidgets('starts down, so nothing is suppressed by default', (
      tester,
    ) async {
      // The default matters more than it looks: anything that forgets to set it
      // gets the shield, not a hole in it.
      expect(privacyShieldSuppressed.value, isFalse);
    });
  });
}
