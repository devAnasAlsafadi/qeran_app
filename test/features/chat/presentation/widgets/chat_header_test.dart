import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_header.dart';

const _peer = MatchmakerInfo(
  matchmakerId: 'mm-1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 42,
);

Future<void> _pump(WidgetTester tester, Widget header) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Column(children: [header])),
  ),
);

Finder get _back => find.byIcon(Icons.chevron_left_rounded);

void main() {
  testWidgets('before the conversation is known: a title and a way back', (
    tester,
  ) async {
    var backs = 0;
    await _pump(
      tester,
      ChatHeader.title(title: 'Your matchmaker', onBack: () => backs++),
    );

    expect(find.text('Your matchmaker'), findsOneWidget);
    await tester.tap(_back);
    expect(backs, 1);
  });

  testWidgets('no back chevron when there is nowhere to go back to', (
    tester,
  ) async {
    await _pump(tester, const ChatHeader.title(title: 'Your matchmaker'));

    expect(_back, findsNothing);
  });

  testWidgets('the conversation shows the peer with the line under her name', (
    tester,
  ) async {
    await _pump(
      tester,
      const ChatHeader.peer(peer: _peer, subtitle: 'Your matchmaker'),
    );

    expect(find.text('Huda'), findsOneWidget);
    expect(find.text('Your matchmaker'), findsOneWidget);
  });

  // The matchmaker's side: the member's name, nothing under it.
  testWidgets('without a subtitle, only the name', (tester) async {
    await _pump(tester, const ChatHeader.peer(peer: _peer));

    expect(find.text('Huda'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2), reason: 'name + monogram');
  });

  // Loading → ready swaps one shape for the other; a height change would
  // make the whole conversation jump.
  testWidgets('both shapes are the same height', (tester) async {
    await _pump(
      tester,
      ChatHeader.title(title: 'Your matchmaker', onBack: () {}),
    );
    final titleHeight = tester.getSize(find.byType(ChatHeader)).height;

    await _pump(
      tester,
      ChatHeader.peer(peer: _peer, subtitle: 'Your matchmaker', onBack: () {}),
    );
    final peerHeight = tester.getSize(find.byType(ChatHeader)).height;

    expect(peerHeight, titleHeight);
  });
}
