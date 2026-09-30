import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:qeran/features/home/presentation/home_shell_navigator.dart';
import 'package:qeran/features/home/presentation/home_tab_switcher.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

const _discovery = HomeShellNavigator.discoveryTab;
const _likes = HomeShellNavigator.likesTab;
const _messages = HomeShellNavigator.messagesTab;
const _profile = HomeShellNavigator.profileTab;

class _Shell {
  _Shell(WidgetTester tester) {
    tabs = HomeTabSwitcher(vsync: tester, initialTab: _discovery);
    navigator = HomeShellNavigator(
      tabs: tabs,
      markTabSeen: seen.add,
      openInbox: () {
        inboxOpens++;
        inbox = Completer<Object?>();
        return inbox.future;
      },
    );
    addTearDown(() {
      navigator.dispose();
      tabs.dispose();
    });
  }

  late final HomeTabSwitcher tabs;
  late final HomeShellNavigator navigator;
  final List<int> seen = [];
  int inboxOpens = 0;
  late Completer<Object?> inbox;
}

void main() {
  testWidgets('a notification opens its tab with a way back to the inbox', (
    tester,
  ) async {
    final shell = _Shell(tester);

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
    final shell = _Shell(tester);
    shell.navigator.onNavTap(_likes);
    await tester.pumpAndSettle();

    shell.navigator.openFromNotification(const OpenLikesTab());

    expect(shell.navigator.backTrail, HomeBackTrail.notifications);
    expect(shell.tabs.currentTab, _likes);
  });

  testWidgets('a notification with nowhere to go changes nothing', (
    tester,
  ) async {
    final shell = _Shell(tester);

    shell.navigator.openFromNotification(const NoDeepLink());

    expect(shell.navigator.backTrail, isNull);
    expect(shell.seen, isEmpty);
  });

  testWidgets('a nav tap ends the trail', (tester) async {
    final shell = _Shell(tester);
    shell.navigator.openFromNotification(const OpenProfileTab());
    await tester.pumpAndSettle();

    shell.navigator.onNavTap(_discovery);
    await tester.pumpAndSettle();

    expect(shell.navigator.backTrail, isNull);
  });

  testWidgets('following the notifications trail reopens the inbox once', (
    tester,
  ) async {
    final shell = _Shell(tester);
    shell.navigator.openFromNotification(const OpenLikesTab());
    await tester.pumpAndSettle();

    shell.navigator.followBackTrail();

    expect(shell.inboxOpens, 1);
    expect(shell.navigator.backTrail, isNull, reason: 'the trail is spent');
  });

  testWidgets('a row tapped in the reopened inbox is applied', (tester) async {
    final shell = _Shell(tester);
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
    final shell = _Shell(tester);
    shell.navigator.openFromNotification(const OpenLikesTab());
    await tester.pumpAndSettle();
    shell.navigator.followBackTrail();

    shell.inbox.complete(null);
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, _likes);
    expect(shell.navigator.backTrail, isNull);
  });

  testWidgets('the Likes trail switches back to Likes and is spent', (
    tester,
  ) async {
    final shell = _Shell(tester);
    shell.navigator.onNavTap(_likes);
    await tester.pumpAndSettle();
    shell.navigator.openMessagesTab(trail: HomeBackTrail.likes);
    await tester.pumpAndSettle();
    expect(shell.tabs.currentTab, _messages);
    expect(shell.navigator.backTrail, HomeBackTrail.likes);

    shell.navigator.followBackTrail();
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, _likes);
    expect(shell.navigator.backTrail, isNull);
  });

  testWidgets('a refresh rebuilds Messages from scratch', (tester) async {
    final shell = _Shell(tester);

    shell.navigator.openMessagesTab(refresh: true);
    await tester.pumpAndSettle();

    expect(shell.navigator.messagesRefreshEpoch, 1);
    expect(shell.tabs.currentTab, _messages);
  });

  // A live event can light a dot on the tab already showing; a tap that
  // ignored it would read as broken.
  testWidgets('a tap acknowledges the badge even on the tab showing', (
    tester,
  ) async {
    final shell = _Shell(tester);

    shell.navigator.onNavTap(_discovery);

    expect(shell.seen, [_discovery]);
  });

  testWidgets('with no trail, back does nothing', (tester) async {
    final shell = _Shell(tester);

    shell.navigator.followBackTrail();

    expect(shell.inboxOpens, 0);
    expect(shell.seen, isEmpty);
  });
}
