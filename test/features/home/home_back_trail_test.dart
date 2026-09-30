import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/home/presentation/widgets/tab_back_row.dart';

/// A tab reached by a switch has nothing to pop, so the shell remembers where
/// the switch came from — the inbox — and the tab offers the way back. What
/// these pin is the destination: a control that shows without a trail sends
/// the user somewhere they never came from.
Widget _host({
  required HomeBackTrail? trail,
  VoidCallback? followBackTrail,
  required Widget Function(HomeShellScope? shell) builder,
}) => MaterialApp(
  home: HomeShellScope(
    openLikesTab: () {},
    openProfileTab: () {},
    openFromNotification: (_) {},
    backTrail: trail,
    followBackTrail: followBackTrail ?? () {},
    child: Builder(builder: (c) => builder(HomeShellScope.maybeOf(c))),
  ),
);

/// What Interests and Profile ask: only the inbox trail reaches them.
Widget _inboxTab(HomeShellScope? shell) =>
    shell?.backTrail == HomeBackTrail.notifications
    ? TabBackRow(onBack: shell!.followBackTrail)
    : const SizedBox.shrink();

void main() {
  testWidgets('a tab reached from the inbox offers a way back to it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(trail: HomeBackTrail.notifications, builder: _inboxTab),
    );

    expect(find.byType(QeranBackButton), findsOneWidget);
  });

  testWidgets('a tapped tab carries no control at all', (tester) async {
    await tester.pumpWidget(_host(trail: null, builder: _inboxTab));

    expect(find.byType(QeranBackButton), findsNothing);
  });

  testWidgets('the control follows the trail rather than a fixed route', (
    tester,
  ) async {
    var followed = 0;
    await tester.pumpWidget(
      _host(
        trail: HomeBackTrail.notifications,
        followBackTrail: () => followed++,
        builder: _inboxTab,
      ),
    );

    await tester.tap(find.byType(QeranBackButton));
    expect(followed, 1);
  });
}
