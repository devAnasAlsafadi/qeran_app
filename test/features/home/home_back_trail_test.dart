import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/home/presentation/widgets/tab_back_row.dart';

/// A tab reached by a switch has nothing to pop, so the shell remembers where
/// the switch came from. Two sources now do that — the inbox and the Likes
/// compatibility list — and they are ONE nullable field rather than a flag
/// each, so "arrived from both" cannot be represented.
///
/// What these pin is the part that a second boolean would have got wrong: the
/// destination. A control that shows for the wrong trail sends the user
/// somewhere they never came from.
Widget _host({
  required HomeBackTrail? trail,
  required Widget Function(HomeShellScope? shell) builder,
}) => MaterialApp(
  home: HomeShellScope(
    openLikesTab: () {},
    openMessagesTab: ({bool refresh = false, HomeBackTrail? trail}) {},
    openProfileTab: () {},
    openFromNotification: (_) {},
    backTrail: trail,
    followBackTrail: () {},
    child: Builder(builder: (c) => builder(HomeShellScope.maybeOf(c))),
  ),
);

/// What Likes and Profile ask: only the inbox trail reaches them.
Widget _inboxOnlyTab(HomeShellScope? shell) =>
    shell?.backTrail == HomeBackTrail.notifications
    ? TabBackRow(onBack: shell!.followBackTrail)
    : const SizedBox.shrink();

/// What Messages asks: any trail at all, because both lead somewhere else.
Widget _anyTrailTab(HomeShellScope? shell) => shell?.backTrail == null
    ? const SizedBox.shrink()
    : TabBackRow(onBack: shell!.followBackTrail);

void main() {
  testWidgets('Messages offers a way back from either trail', (tester) async {
    for (final trail in HomeBackTrail.values) {
      await tester.pumpWidget(_host(trail: trail, builder: _anyTrailTab));
      expect(
        find.byType(QeranBackButton),
        findsOneWidget,
        reason: 'trail: ${trail.name}',
      );
    }
  });

  // The bug a second boolean invites: the user sends an inquiry from Likes,
  // lands on Messages, and Likes would light up a control pointing at an inbox
  // they never opened.
  testWidgets('Likes stays clean while its own trail is live', (tester) async {
    await tester.pumpWidget(
      _host(trail: HomeBackTrail.likes, builder: _inboxOnlyTab),
    );

    expect(find.byType(QeranBackButton), findsNothing);
  });

  testWidgets('Likes offers a way back to the inbox', (tester) async {
    await tester.pumpWidget(
      _host(trail: HomeBackTrail.notifications, builder: _inboxOnlyTab),
    );

    expect(find.byType(QeranBackButton), findsOneWidget);
  });

  testWidgets('a tapped tab carries no control at all', (tester) async {
    for (final builder in [_inboxOnlyTab, _anyTrailTab]) {
      await tester.pumpWidget(_host(trail: null, builder: builder));
      expect(find.byType(QeranBackButton), findsNothing);
    }
  });

  testWidgets('the control follows the trail rather than a fixed route', (
    tester,
  ) async {
    var followed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellScope(
          openLikesTab: () {},
          openMessagesTab: ({bool refresh = false, HomeBackTrail? trail}) {},
          openProfileTab: () {},
          openFromNotification: (_) {},
          backTrail: HomeBackTrail.likes,
          followBackTrail: () => followed++,
          child: Builder(
            builder: (c) =>
                TabBackRow(onBack: HomeShellScope.maybeOf(c)!.followBackTrail),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(QeranBackButton));
    expect(followed, 1);
  });
}
