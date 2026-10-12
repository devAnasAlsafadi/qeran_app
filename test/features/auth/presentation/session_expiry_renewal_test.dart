import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';

import '../../../core/shipped_strings_rig.dart';
import 'session_expiry_rig.dart';

/// A password change replaces the token, and the server refuses the old one
/// at once: a 401 the old token meets while the change is in flight waits for
/// it, and is judged against the token the change brings.
void main() {
  setUpAll(initShippedStrings);

  late ExpiryRig rig;

  setUp(() {
    AppSnackBar.debugReset();
    rig = ExpiryRig();
  });

  tearDown(AppSnackBar.debugReset);

  /// A password change whose answer waits for [answer], then stores [token]
  /// (none: it failed, or came before Tariq's deploy).
  Future<void> change(Completer<void> answer, {String? token}) =>
      rig.expiry.renewing(() async {
        await answer.future;
        if (token != null) rig.secure.values[StorageKeys.token] = token;
      });

  testWidgets('a 401 during the change waits for it; with the new token in, '
      'no one is signed out', (tester) async {
    await rig.openApp(tester, at: RouteNames.homeScreen);
    final answer = Completer<void>();
    final changed = change(answer, token: 'jwt-2');

    rig.expiry.report('jwt-1');
    await rig.handled(tester);
    expect(rig.signOuts, 0, reason: 'held while the change is in flight');

    answer.complete();
    await changed;
    await rig.handled(tester);

    expect(rig.signOuts, 0);
    expect(find.text('route ${RouteNames.homeScreen}'), findsOneWidget);
  });

  testWidgets('a 401 the old token meets after the change is ignored', (
    tester,
  ) async {
    await rig.openApp(tester, at: RouteNames.homeScreen);
    await change(Completer<void>()..complete(), token: 'jwt-2');

    rig.expiry.report('jwt-1');
    await rig.handled(tester);

    expect(rig.signOuts, 0);
  });

  testWidgets('a change that brought no token: the held 401 is real, and '
      'signs out', (tester) async {
    await rig.openApp(tester, at: RouteNames.homeScreen);
    final answer = Completer<void>();
    final changed = change(answer);

    rig.expiry.report('jwt-1');
    await rig.handled(tester);
    answer.complete();
    await changed;
    await rig.handled(tester);

    expect(rig.signOuts, 1);
    await rig.dismissed(tester);
  });
}
