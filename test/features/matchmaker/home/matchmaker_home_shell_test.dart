import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/screens/matchmaker_cases_tab.dart';
import 'package:qeran/features/matchmaker/conversations/domain/entities/matchmaker_conversation.dart';
import 'package:qeran/features/matchmaker/home/presentation/widgets/matchmaker_bottom_nav.dart';

import '../../../core/shipped_strings_rig.dart';
import 'her_shell_rig.dart';

Map<String, dynamic> _caseUpdate({String? audience = 'matchmaker'}) => {
  'action': 'compatibility_case_updated',
  'caseId': '4',
  'audience': ?audience,
};

const _chat = {'type': 'chat', 'conversationId': '12', 'senderName': 'Dima'};

const _member = UserEntity(
  id: 'u-2',
  name: 'Dima',
  email: 'dima@test.com',
  token: 'jwt',
  role: 'User',
);

Finder _navItem(String label) => find.descendant(
  of: find.byType(MatchmakerBottomNav),
  matching: find.text(label),
);

/// Her shell as it stands before the split: what a tapped push opens, the
/// trail back to the inbox, and tabs that mount on their first visit.
void main() {
  setUpAll(initShippedStrings);
  tearDown(sl.reset);

  testWidgets('a push that launched the app (killed) opens Cases, with a way '
      'back to the inbox that spends the trail', (tester) async {
    final shell = HerShellRig(launchedBy: push(_caseUpdate()));
    await shell.pump(tester);

    expect(shell.tab(tester), 2);
    expect(shell.trail(tester), isTrue);
    expect(shell.badges.seen, [BadgeTabKeys.cases]);

    await tester.tap(find.byType(QeranBackButton));
    await tester.pumpAndSettle();
    expect(shell.inboxOpens, 1);
    expect(shell.trail(tester), isFalse);
  });

  testWidgets('a chat push tapped in the background opens the chat over the '
      'shell, named from the push, and raises the trail', (tester) async {
    final shell = HerShellRig();
    await shell.pump(tester);

    shell.opened.add(push(_chat));
    await tester.pumpAndSettle();

    final chat = shell.chats.single! as MatchmakerConversation;
    expect((chat.conversationId, chat.fullName), (12, 'Dima'));
    expect(find.text('chat'), findsOneWidget);
    expect(shell.tab(tester), 0);
    expect(shell.trail(tester), isTrue);
  });

  testWidgets('only what is addressed to her: a member\'s case update, or a '
      'payload she has no use for, does nothing', (tester) async {
    final shell = HerShellRig();
    await shell.pump(tester);

    shell.opened
      ..add(push(_caseUpdate(audience: 'member')))
      ..add(push(_caseUpdate(audience: null)))
      ..add(push(const {'type': 'general'}));
    await tester.pumpAndSettle();

    expect(shell.tab(tester), 0);
    expect(shell.trail(tester), isFalse);
    expect(shell.chats, isEmpty);
  });

  testWidgets('a push while a member is signed in does nothing', (
    tester,
  ) async {
    final shell = HerShellRig(launchedBy: push(_caseUpdate()), user: _member);
    await shell.pump(tester);

    expect(shell.tab(tester), 0);
    expect(shell.trail(tester), isFalse);
  });

  testWidgets('system back with the trail live reopens the inbox, and a case '
      'tapped there opens Cases again', (tester) async {
    final shell = HerShellRig(launchedBy: push(_caseUpdate()));
    await shell.pump(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(shell.inboxOpens, 1);

    await tester.tap(find.text('a case row'));
    await tester.pumpAndSettle();
    expect(shell.tab(tester), 2);
    expect(shell.trail(tester), isTrue);
    expect(find.byType(QeranBackButton), findsOneWidget);
  });

  testWidgets('leaving the inbox without a tap leaves an ordinary tab; back '
      'then reopens nothing', (tester) async {
    final shell = HerShellRig(launchedBy: push(_caseUpdate()));
    await shell.pump(tester);

    await tester.tap(find.byType(QeranBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('leave'));
    await tester.pumpAndSettle();

    expect(shell.tab(tester), 2);
    expect(find.byType(QeranBackButton), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(shell.inboxOpens, 1);
  });

  testWidgets('a bottom-nav tap ends the trail', (tester) async {
    final shell = HerShellRig(launchedBy: push(_caseUpdate()));
    await shell.pump(tester);

    await tester.tap(_navItem('Dashboard'));
    await tester.pumpAndSettle();
    expect((shell.tab(tester), shell.trail(tester)), (0, false));

    await tester.tap(_navItem('Cases'));
    await tester.pumpAndSettle();
    expect(shell.tab(tester), 2);
    expect(find.byType(QeranBackButton), findsNothing);
  });

  testWidgets('a tab mounts on its first visit and stays', (tester) async {
    final shell = HerShellRig();
    await shell.pump(tester);
    final cases = find.byType(MatchmakerCasesTab, skipOffstage: false);
    expect(cases, findsNothing);

    await tester.tap(_navItem('Cases'));
    await tester.pumpAndSettle();
    await tester.tap(_navItem('Dashboard'));
    await tester.pumpAndSettle();

    expect(cases, findsOneWidget);
    expect(shell.badges.seen, [BadgeTabKeys.cases]);
  });
}
