import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/widgets/shell_top_bar_host.dart';

/// A tab reached by a switch has nothing to pop, so the shell remembers where
/// the switch came from — the inbox — and the shell's top bar offers the way
/// back. What these pin is the destination: a control that shows without a
/// trail sends the user somewhere they never came from.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('a tab reached from the inbox gets a way back in the bar', (
    tester,
  ) async {
    await pumpShellTopBar(
      tester,
      matchmaker: await matchmakerCubit(null),
      trail: HomeBackTrail.notifications,
    );

    expect(find.byType(QeranBackButton), findsOneWidget);
  });

  testWidgets('a tapped tab: the bar carries no control at all', (
    tester,
  ) async {
    await pumpShellTopBar(tester, matchmaker: await matchmakerCubit(null));

    expect(find.byType(QeranBackButton), findsNothing);
  });

  testWidgets('the control follows the trail rather than a fixed route', (
    tester,
  ) async {
    var followed = 0;
    await pumpShellTopBar(
      tester,
      matchmaker: await matchmakerCubit(null),
      trail: HomeBackTrail.notifications,
      followBackTrail: () => followed++,
    );

    await tester.tap(find.byType(QeranBackButton));
    expect(followed, 1);
  });
}
