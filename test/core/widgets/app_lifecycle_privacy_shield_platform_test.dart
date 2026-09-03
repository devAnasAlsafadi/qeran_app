import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'privacy_shield_harness.dart';

/// `inactive` is the one lifecycle state the platforms disagree about, so it
/// gets its own suite where every case names the platform it means.
///
/// On iOS it is the state an app-switcher gesture produces while the app is
/// still on screen, shrinking into its card — and iOS has no FLAG_SECURE
/// equivalent, so this Flutter fill is the ONLY thing covering that content
/// (QER-3). On Android the window is kept out of recents natively by
/// FLAG_SECURE, and `inactive` also fires for transient focus loss the user is
/// still looking at: a permission prompt, the notification shade, the
/// screenshot preview overlay.
void main() {
  testWidgets('iOS conceals on inactive — the app-switcher gesture', (
    tester,
  ) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.inactive);

    // The card the switcher renders must already be covered. This is the whole
    // reason the shield exists; narrowing it here would remove the protection,
    // not just the flashes.
    expect(concealer(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS lifts the fill again on resumed', (tester) async {
    await pumpShield(tester);
    await lifecycle(tester, AppLifecycleState.inactive);
    expect(concealer(), findsOneWidget);

    await lifecycle(tester, AppLifecycleState.resumed);

    expect(concealer(), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('android does NOT conceal on inactive', (tester) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.inactive);

    // The regression guard for the flashes. `inactive` on android is a
    // permission prompt, the shade, the screenshot preview — the window is
    // still on screen and the user is looking at it. Painting wine here is the
    // bug, not the protection.
    expect(concealer(), findsNothing);
    expect(find.text('protected content'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a platform we did not reason about keeps concealing', (
    tester,
  ) async {
    await pumpShield(tester);

    await lifecycle(tester, AppLifecycleState.inactive);

    // Only android is special. Anything else keeps the original rule, so a
    // future target is never left exposed by default.
    expect(concealer(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
