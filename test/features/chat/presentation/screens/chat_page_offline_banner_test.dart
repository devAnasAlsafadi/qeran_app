import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/presentation/screens/chat_conversation_screen.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_header.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_page_host.dart';

/// Offline, the member's chat shows the banner under its header, so the back
/// chevron stays reachable. The matchmaker's chat shares the header and keeps
/// the overlay.
Rect _banner(WidgetTester tester) {
  expect(find.text(LocaleKeys.errors_offline), findsOneWidget);
  return tester.getRect(
    find
        .ancestor(
          of: find.text(LocaleKeys.errors_offline),
          matching: find.byType(Material),
        )
        .first,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());

  testWidgets('loading: the banner sits under the header', (tester) async {
    registerChatPage(Completer<Either<Failure, MyMatchmakerOutcome>>().future);
    await openChatPage(tester, offline: true);
    // The loader never settles; let the banners finish trading places.
    await tester.pump(const Duration(seconds: 1));

    expect(_banner(tester).top, tester.getRect(find.byType(ChatHeader)).bottom);
  });

  testWidgets('the conversation: the banner sits under the header', (
    tester,
  ) async {
    registerChatPage(
      Future.value(const Right(MyMatchmakerAssigned(info: kHuda))),
    );
    await openChatPage(tester, offline: true);
    await tester.pumpAndSettle();

    expect(find.text('Huda'), findsOneWidget);
    expect(_banner(tester).top, tester.getRect(find.byType(ChatHeader)).bottom);
  });

  testWidgets('the matchmaker\'s conversation keeps the overlay', (
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
        offline: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(_banner(tester).top, 0);
  });
}
