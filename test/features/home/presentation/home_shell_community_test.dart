import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:qeran/features/home/presentation/home_shell_navigator.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

import 'home_shell_rig.dart';

const _post = OpenCommunityPost(
  postId: 5,
  landing: CommunityLanding(commentId: 40, replyId: 41),
);

/// A Community notification's post is pushed over the shell like the chat
/// (H1); «العودة إلى المجتمع» on a post that's gone goes back to Community
/// (Q12).
void main() {
  testWidgets('a post notification pushes the post, at its landing, and '
      'leaves no trail', (tester) async {
    final shell = ShellRig(tester);
    shell.navigator.onNavTap(HomeShellNavigator.profileTab);
    await tester.pumpAndSettle();

    shell.navigator.openFromNotification(_post);
    await tester.pumpAndSettle();

    expect(shell.posts, [_post]);
    expect(shell.navigator.backTrail, isNull);
    expect(shell.tabs.currentTab, HomeShellNavigator.profileTab);
  });

  testWidgets('closed with back: the tab underneath stays', (tester) async {
    final shell = ShellRig(tester);
    shell.navigator.onNavTap(HomeShellNavigator.profileTab);
    await tester.pumpAndSettle();
    shell.navigator.openFromNotification(_post);

    shell.post.complete(false);
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, HomeShellNavigator.profileTab);
  });

  testWidgets('closed on «العودة إلى المجتمع»: Community, and the trail is '
      'spent', (tester) async {
    final shell = ShellRig(tester);
    shell.navigator.openFromNotification(const OpenLikesTab());
    await tester.pumpAndSettle();
    expect(shell.navigator.backTrail, HomeBackTrail.notifications);
    shell.navigator.openFromNotification(_post);

    shell.post.complete(true);
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, HomeShellNavigator.communityTab);
    expect(shell.navigator.backTrail, isNull);
  });

  testWidgets('the inbox handing back the Community tab selects it, with no '
      'trail', (tester) async {
    final shell = ShellRig(tester);
    shell.navigator.onNavTap(HomeShellNavigator.likesTab);
    await tester.pumpAndSettle();

    shell.navigator.openFromNotification(const OpenCommunityTab());
    await tester.pumpAndSettle();

    expect(shell.tabs.currentTab, HomeShellNavigator.communityTab);
    expect(shell.navigator.backTrail, isNull);
  });
}
