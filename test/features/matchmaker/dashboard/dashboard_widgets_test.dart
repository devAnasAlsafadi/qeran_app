import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';
import 'package:qeran/features/matchmaker/dashboard/domain/entities/matchmaker_dashboard_stats.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_attention_card.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_attention_row.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_dashboard_skeleton.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_dashboard_tabs.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_greeting_row.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_overview_grid.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_users_list.dart';

import '../../../core/shipped_strings_rig.dart';

/// Her Dashboard's widgets as they stand before E2 splits their long builds
/// (characterization): the counters, the urgent dot, the calm zero line, the
/// greeting, and the skeleton.
String _en(String key) =>
    (jsonDecode(
              File('assets/translations/en.json').readAsStringSync(),
            )['matchmaker']
            as Map<String, dynamic>)[key]
        as String;

const _stats = MatchmakerDashboardStats(
  pendingUsersCount: 3,
  approvedSubscribedCount: 11,
  approvedUnsubscribedCount: 22,
  activeCompatibilityCasesCount: 33,
  unreadMessagesCount: 0,
  totalAssignedUsers: 44,
);

final _urgentDot = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_UrgentDot',
);

void main() {
  setUpAll(initShippedStrings);

  final opened = <(int, MatchmakerUsersList?)>[];
  void onOpen(int index, {MatchmakerUsersList? usersSubTab}) =>
      opened.add((index, usersSubTab));
  setUp(opened.clear);

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      child: SingleChildScrollView(child: child),
      settle: false,
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the two heroes: a count with its dot, and the calm zero', (
    tester,
  ) async {
    await pump(
      tester,
      IntrinsicHeight(
        // As the Dashboard hosts it: equal-height heroes.
        child: MatchmakerAttentionRow(stats: _stats, onOpen: onOpen),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text(_en('dashboard_pending')), findsOneWidget);
    expect(find.text(_en('dashboard_hero_action')), findsOneWidget);
    expect(_urgentDot, findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text(_en('dashboard_unread_zero')), findsOneWidget);
    expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.tap(find.text('0'));
    expect(opened, [
      (MatchmakerDashboardTabs.users, MatchmakerUsersList.pending),
      (MatchmakerDashboardTabs.conversations, null),
    ]);
  });

  testWidgets('no pulse: a count without its dot', (tester) async {
    await pump(
      tester,
      MatchmakerAttentionCard(
        icon: Icons.inbox,
        count: 5,
        label: 'L',
        actionLabel: 'A',
        zeroLabel: 'Z',
        onTap: () {},
        pulse: false,
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(_urgentDot, findsNothing);
  });

  testWidgets('the four tiles: their counts, and where each leads', (
    tester,
  ) async {
    await pump(tester, MatchmakerOverviewGrid(stats: _stats, onOpen: onOpen));

    for (final count in ['11', '22', '33', '44']) {
      expect(find.text(count), findsOneWidget);
      await tester.tap(find.text(count));
    }
    expect(find.text(_en('dashboard_active_cases')), findsOneWidget);
    expect(opened, [
      (MatchmakerDashboardTabs.users, MatchmakerUsersList.approvedSubscribed),
      (MatchmakerDashboardTabs.users, MatchmakerUsersList.approvedUnsubscribed),
      (MatchmakerDashboardTabs.cases, null),
      (MatchmakerDashboardTabs.users, null),
    ]);
  });

  testWidgets('the greeting: her name over the salaam, and the date', (
    tester,
  ) async {
    await pump(
      tester,
      MatchmakerGreetingRow(name: ' Huda ', now: DateTime(2026, 10, 9, 14)),
    );

    expect(find.text('Huda'), findsOneWidget);
    expect(find.text(_en('dashboard_salaam_afternoon')), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('Oct'), findsOneWidget);
  });

  testWidgets('no name: the salaam alone; no date when asked', (tester) async {
    await pump(
      tester,
      MatchmakerGreetingRow(
        name: '  ',
        showDate: false,
        now: DateTime(2026, 10, 9, 20),
      ),
    );

    expect(find.text(_en('dashboard_salaam_evening')), findsOneWidget);
    expect(find.text('Friday'), findsNothing);
  });

  testWidgets('the skeleton: greeting, two heroes, four tiles', (tester) async {
    await pump(
      tester,
      const SizedBox(height: 900, child: MatchmakerDashboardBodySkeleton()),
    );

    expect(find.byType(QeranSkeleton), findsNWidgets(11));
  });
}
