import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_system_bars.dart';
import 'package:qeran/core/design_system/widgets/qeran_bell_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';
import 'package:qeran/core/design_system/widgets/qeran_dashed_ring.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/presentation/widgets/matchmaker_avatar.dart';
import 'package:qeran/features/home/presentation/widgets/shell_top_bar.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shell_top_bar_host.dart';

const _chatUnread = BadgeCounts({BadgeTabKeys.chat: 2});

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('the matchmaker block', () {
    testWidgets('before she is known: the role line over a neutral avatar', (
      tester,
    ) async {
      await pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(null),
        badges: _chatUnread,
      );

      expect(find.text(LocaleKeys.shell_matchmaker_role), findsOneWidget);
      expect(find.byType(QeranMonogram), findsOneWidget);
      expect(find.byType(QeranChip), findsNothing, reason: 'no one to chat');
      expect(find.bySemanticsLabel(LocaleKeys.shell_matchmaker_role), findsOne);
    });

    testWidgets('none assigned yet: says so, and never carries the chip', (
      tester,
    ) async {
      await pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(
          const MyMatchmakerNotAssigned(serverMessage: ''),
        ),
        badges: _chatUnread,
      );

      expect(find.text(LocaleKeys.shell_matchmaker_assigning), findsOneWidget);
      expect(find.byType(QeranDashedRing), findsOneWidget);
      expect(find.byType(QeranChip), findsNothing);
    });

    testWidgets('known: her name and avatar, no chip while the chat is read', (
      tester,
    ) async {
      await pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(
          const MyMatchmakerAssigned(info: kHuda),
        ),
      );

      expect(find.text('Huda'), findsOneWidget);
      expect(find.byType(MatchmakerAvatar), findsOneWidget);
      expect(find.byType(QeranChip), findsNothing);
      expect(find.bySemanticsLabel(LocaleKeys.shell_chat_entry_a11y), findsOne);
    });

    testWidgets('unread chat adds «رسالة جديدة» and says it aloud', (
      tester,
    ) async {
      await pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(
          const MyMatchmakerAssigned(info: kHuda),
        ),
        badges: _chatUnread,
      );

      expect(find.text(LocaleKeys.shell_chat_unread), findsOneWidget);
      expect(
        find.bySemanticsLabel(LocaleKeys.shell_chat_entry_a11y_unread),
        findsOne,
      );
    });

    testWidgets('the whole block is one tap target that opens the chat', (
      tester,
    ) async {
      var opened = 0;
      await pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(
          const MyMatchmakerAssigned(info: kHuda),
        ),
        onOpenChat: () => opened++,
      );

      await tester.tap(find.text(LocaleKeys.shell_matchmaker_role));
      await tester.tap(find.byType(MatchmakerAvatar));

      expect(opened, 2);
    });
  });

  group('the bell', () {
    testWidgets('opens the inbox, with no count while nothing is unread', (
      tester,
    ) async {
      var opened = 0;
      await pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(null),
        onOpenInbox: () => opened++,
      );

      expect(find.byType(QeranCountBadge), findsNothing);
      await tester.tap(find.byType(QeranBellButton));
      expect(opened, 1);
    });

    testWidgets('carries the unread count', (tester) async {
      await pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(null),
        badges: const BadgeCounts({BadgeTabKeys.notifications: 5}),
      );

      expect(find.byType(QeranCountBadge), findsOneWidget);
    });

    testWidgets('is 26 pt, as the board draws it', (tester) async {
      await pumpShellTopBar(tester, matchmaker: await matchmakerCubit(null));

      final glyph = tester.widget<Icon>(
        find.byIcon(Icons.notifications_none_rounded),
      );
      expect(glyph.size, 26);
    });
  });

  group('the bar', () {
    testWidgets('is 64 pt tall, 56 in landscape', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final matchmaker = await matchmakerCubit(null);

      tester.view.physicalSize = const Size(400, 800);
      await pumpShellTopBar(tester, matchmaker: matchmaker);
      expect(tester.getSize(find.byType(ShellTopBar)).height, 64);

      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(ShellTopBar)).height, 56);
    });

    testWidgets('asks for dark status-bar icons over its paper', (
      tester,
    ) async {
      await pumpShellTopBar(tester, matchmaker: await matchmakerCubit(null));

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(
          of: find.byType(ShellTopBar),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ),
      );
      expect(region.value, QeranSystemBars.darkIcons);
    });
  });
}
