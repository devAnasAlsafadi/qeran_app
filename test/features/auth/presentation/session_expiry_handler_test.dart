import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';

import '../../../core/shipped_strings_rig.dart';
import 'session_expiry_rig.dart';

/// C4 (Q25, TQ11): a 401 to our Bearer signs out once, however many requests
/// fail together, and lands on login with «انتهت الجلسة», in both roles. Only
/// while the token is still the stored one, and never before the splash has
/// routed.
void main() {
  setUpAll(initShippedStrings);

  late ExpiryRig rig;

  setUp(() {
    AppSnackBar.debugReset();
    rig = ExpiryRig();
  });

  tearDown(AppSnackBar.debugReset);

  for (final home in [RouteNames.homeScreen, RouteNames.matchmakerHome]) {
    testWidgets('three 401s at once: one sign-out, login on top, one notice '
        '[$home]', (tester) async {
      await rig.openApp(tester, at: home);

      rig.expiry
        ..report('jwt-1')
        ..report('jwt-1')
        ..report('jwt-1');
      await rig.handled(tester);

      expect(rig.signOuts, 1);
      expect(find.text('route ${RouteNames.loginScreen}'), findsOneWidget);
      expect(find.text('route $home', skipOffstage: false), findsNothing);
      expect(find.text(expiredNotice), findsOneWidget);
      await rig.dismissed(tester);
    });
  }

  testWidgets('a token already replaced (a new sign-in) is not this '
      'session\'s', (tester) async {
    await rig.openApp(tester, at: RouteNames.homeScreen);
    rig.secure.values[StorageKeys.token] = 'jwt-2';

    rig.expiry.report('jwt-1');
    await rig.handled(tester);

    expect(rig.signOuts, 0);
    expect(find.text('route ${RouteNames.homeScreen}'), findsOneWidget);
  });

  testWidgets('a late 401 from the old token, after the sign-out, changes '
      'nothing', (tester) async {
    await rig.openApp(tester, at: RouteNames.homeScreen);
    rig.expiry.report('jwt-1');
    await rig.handled(tester);

    rig.expiry.report('jwt-1');
    await rig.handled(tester);

    expect(rig.signOuts, 1);
    await rig.dismissed(tester);
  });

  testWidgets('on the splash, it waits for the splash to route, then signs '
      'out', (tester) async {
    await rig.openApp(tester);

    rig.expiry.report('jwt-1');
    await rig.handled(tester);
    expect(rig.signOuts, 0, reason: 'the splash has not routed yet');

    await rig.routeTo(tester, RouteNames.homeScreen);
    await rig.handled(tester);

    expect(rig.signOuts, 1);
    expect(find.text('route ${RouteNames.loginScreen}'), findsOneWidget);
    await rig.dismissed(tester);
  });
}
