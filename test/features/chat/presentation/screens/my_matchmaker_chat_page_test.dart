import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_system_bars.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/presentation/screens/chat_conversation_screen.dart';
import 'package:qeran/features/chat/presentation/screens/my_matchmaker_chat_page.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_page_host.dart';

Finder get _back => find.byIcon(Icons.chevron_left_rounded);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());

  final entryStates = <String, Future<Either<Failure, MyMatchmakerOutcome>>>{
    'loading': Completer<Either<Failure, MyMatchmakerOutcome>>().future,
    'being assigned': Future.value(
      const Right(MyMatchmakerNotAssigned(serverMessage: '')),
    ),
    'failure': Future.value(const Left(ServerFailure(message: 'network'))),
  };

  for (final entry in entryStates.entries) {
    testWidgets('${entry.key}: titled, with a back that closes the page', (
      tester,
    ) async {
      registerChatPage(entry.value);
      await openChatPage(tester);

      expect(find.text('shell.matchmaker_role'), findsOneWidget);
      await tester.tap(_back);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MyMatchmakerChatPage), findsNothing);
    });
  }

  testWidgets('the member sees the role under the matchmaker\'s name', (
    tester,
  ) async {
    registerChatPage(
      Future.value(const Right(MyMatchmakerAssigned(info: kHuda))),
    );
    await openChatPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Huda'), findsOneWidget);
    expect(find.text('shell.matchmaker_role'), findsOneWidget);
    expect(find.text('chat.empty_start_with'), findsOneWidget);
    expect(_back, findsOneWidget);
  });

  testWidgets('the matchmaker\'s side has no role line and its own voice', (
    tester,
  ) async {
    registerChatPage(
      Future.value(const Right(MyMatchmakerAssigned(info: kHuda))),
    );
    await tester.pumpWidget(
      chatApp(
        const Scaffold(
          body: ChatConversationScreen(
            info: kHuda,
            viewer: ChatViewer.matchmaker,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Huda'), findsOneWidget);
    expect(find.text('shell.matchmaker_role'), findsNothing);
    expect(find.text('chat.empty_start_with_matchmaker'), findsOneWidget);
  });

  // No canvas strip above the header: the paper starts at the top edge.
  testWidgets('the header runs under the status bar', (tester) async {
    registerChatPage(
      Future.value(const Right(MyMatchmakerAssigned(info: kHuda))),
    );
    await openChatPage(tester);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(ChatHeader)).dy, 0);
    expect(tester.getTopLeft(find.text('Huda')).dy, greaterThan(40));
  });

  testWidgets('the page asks for dark status-bar icons', (tester) async {
    registerChatPage(
      Future.value(const Right(MyMatchmakerAssigned(info: kHuda))),
    );
    await openChatPage(tester);

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
    );
    expect(region.value, QeranSystemBars.darkIcons);
  });
}
