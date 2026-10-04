import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:qeran/features/home/presentation/home_shell_navigator.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

import 'home_shell_rig.dart';

const _community = HomeShellNavigator.communityTab;
const _likes = HomeShellNavigator.likesTab;
const _profile = HomeShellNavigator.profileTab;

void main() {
  testWidgets('a notification opens its tab with a way back to the inbox', (
    tester,
  ) async {
    final shell = ShellRig(tester);

    shell.navigator.openFromNotification(const OpenLikesTab());
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, _likes);
    expect(shell.navigator.backTrail, HomeBackTrail.notifications);
  });

  // Nothing else on screen changes in this case, so the back control is the
  // only sign the tap did anything.
  testWidgets('the trail is raised even when the tab is already showing', (
    tester,
  ) async {
    final shell = ShellRig(tester);
    shell.navigator.onNavTap(_likes);
    await tester.pumpAndSettle();

    shell.navigator.openFromNotification(const OpenLikesTab());

    expect(shell.navigator.backTrail, HomeBackTrail.notifications);
    expect(shell.tabs.currentTab, _likes);
  });

  testWidgets('a notification with nowhere to go changes nothing', (
    tester,
  ) async {
    final shell = ShellRig(tester);

    shell.navigator.openFromNotification(const NoDeepLink());

    expect(shell.navigator.backTrail, isNull);
    expect(shell.seen, isEmpty);
  });

  testWidgets('a nav tap ends the trail', (tester) async {
    final shell = ShellRig(tester);
    shell.navigator.openFromNotification(const OpenProfileTab());
    await tester.pumpAndSettle();

    shell.navigator.onNavTap(_community);
    await tester.pumpAndSettle();

    expect(shell.navigator.backTrail, isNull);
  });

  testWidgets('following the notifications trail reopens the inbox once', (
    tester,
  ) async {
    final shell = ShellRig(tester);
    shell.navigator.openFromNotification(const OpenLikesTab());
    await tester.pumpAndSettle();

    shell.navigator.followBackTrail();

    expect(shell.inboxOpens, 1);
    expect(shell.navigator.backTrail, isNull, reason: 'the trail is spent');
  });

  testWidgets('a row tapped in the reopened inbox is applied', (tester) async {
    final shell = ShellRig(tester);
    shell.navigator.openFromNotification(const OpenLikesTab());
    await tester.pumpAndSettle();
    shell.navigator.followBackTrail();

    shell.inbox.complete(const OpenProfileTab());
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, _profile);
    expect(shell.navigator.backTrail, HomeBackTrail.notifications);
  });

  testWidgets('closing the reopened inbox leaves an ordinary tab', (
    tester,
  ) async {
    final shell = ShellRig(tester);
    shell.navigator.openFromNotification(const OpenLikesTab());
    await tester.pumpAndSettle();
    shell.navigator.followBackTrail();

    shell.inbox.complete(null);
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, _likes);
    expect(shell.navigator.backTrail, isNull);
  });

  // The chat is pushed over whatever shows, so its own back returns there. A
  // trail would leave the tab underneath pointing at an inbox.
  testWidgets('a chat notification pushes the chat and leaves no trail', (
    tester,
  ) async {
    final shell = ShellRig(tester);

    shell.navigator.openFromNotification(const OpenMatchmakerChat());
    await tester.pumpAndSettle();

    expect(shell.chatOpens, 1);
    expect(shell.navigator.backTrail, isNull);
    expect(shell.tabs.currentTab, _community);
    expect(shell.seen, isEmpty);
  });

  // A live event can light a dot on the tab already showing; a tap that
  // ignored it would read as broken.
  testWidgets('a tap acknowledges the badge even on the tab showing', (
    tester,
  ) async {
    final shell = ShellRig(tester);

    shell.navigator.onNavTap(_community);

    expect(shell.seen, [_community]);
  });

  testWidgets('with no trail, back does nothing', (tester) async {
    final shell = ShellRig(tester);

    shell.navigator.followBackTrail();

    expect(shell.inboxOpens, 0);
    expect(shell.seen, isEmpty);
  });
}
