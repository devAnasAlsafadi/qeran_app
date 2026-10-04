import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/home/presentation/home_shell_navigator.dart';
import 'package:qeran/features/home/presentation/home_tab_switcher.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

/// The shell's navigator on Community, with what it opens recorded: the
/// inbox (answered through [inbox]), the chat, and posts (answered through
/// [post]).
class ShellRig {
  ShellRig(WidgetTester tester) {
    tabs = HomeTabSwitcher(
      vsync: tester,
      initialTab: HomeShellNavigator.communityTab,
    );
    navigator = HomeShellNavigator(
      tabs: tabs,
      markTabSeen: seen.add,
      openInbox: () {
        inboxOpens++;
        inbox = Completer<Object?>();
        return inbox.future;
      },
      openChat: () => chatOpens++,
      openPost: (link) {
        posts.add(link);
        post = Completer<bool>();
        return post.future;
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
  int chatOpens = 0;
  final List<OpenCommunityPost> posts = [];
  late Completer<Object?> inbox;
  late Completer<bool> post;
}
