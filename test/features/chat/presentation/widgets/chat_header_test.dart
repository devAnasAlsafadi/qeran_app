import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_header.dart';

const _peer = MatchmakerInfo(
  matchmakerId: 'mm-1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 42,
);

Future<void> _pump(
  WidgetTester tester,
  Widget header, {
  TextDirection ui = TextDirection.ltr,
}) => tester.pumpWidget(
  MaterialApp(
    builder: (_, child) => Directionality(textDirection: ui, child: child!),
    home: Scaffold(body: Column(children: [header])),
  ),
);

MatchmakerInfo _named(String name) => MatchmakerInfo(
  matchmakerId: 'mm-1',
  name: name,
  profileImageUrl: null,
  conversationId: 42,
);

/// The paragraph [name] is laid out in, and the box of its first letter.
(RenderParagraph, TextBox) _firstLetter(WidgetTester tester, String name) {
  final line = tester.renderObject<RenderParagraph>(find.text(name));
  final box = line
      .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
      .single;
  return (line, box);
}

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

  // The name is laid out in its own direction, not the UI's, so a long one
  // gives way at its own end: its first letter keeps the edge its reader
  // starts from, and the ellipsis takes the other.
  group('the name keeps its own direction', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1080, 2340);
      view.devicePixelRatio = 3;
      addTearDown(view.reset);
    });

    testWidgets('an Arabic name in the English UI', (tester) async {
      const name = 'هدى عبدالرحمن محمد الخطيب الأنصاري الحسيني';
      await _pump(tester, ChatHeader.peer(peer: _named(name)));

      final (line, first) = _firstLetter(tester, name);
      expect(line.didExceedMaxLines, isTrue);
      expect(first.right, line.size.width);
    });

    testWidgets('a Latin name in the Arabic UI', (tester) async {
      const name = 'Huda Abdulrahman Mohammed Al-Khatib Al-Ansari';
      await _pump(
        tester,
        ChatHeader.peer(peer: _named(name)),
        ui: TextDirection.rtl,
      );

      final (line, first) = _firstLetter(tester, name);
      expect(line.didExceedMaxLines, isTrue);
      expect(first.left, 0);
    });

    testWidgets('a short one still starts where the UI starts', (tester) async {
      await _pump(
        tester,
        ChatHeader.peer(peer: _named('هدى'), subtitle: 'Your matchmaker'),
      );

      expect(
        tester.getTopLeft(find.text('هدى')).dx,
        tester.getTopLeft(find.text('Your matchmaker')).dx,
      );
    });
  });
}
