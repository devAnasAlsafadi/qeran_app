import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/widgets/scroll_hiding_nav_scaffold.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/matchmaker/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/matchmaker/home/presentation/matchmaker_push_taps.dart';
import 'package:qeran/features/matchmaker/home/presentation/screens/matchmaker_home_screen.dart';
import 'package:qeran/features/matchmaker/shared/data/matchmaker_notification_router.dart';

import '../../../core/shipped_strings_rig.dart';
import '../../auth/presentation/fake_session.dart';
import '../../community/fixtures/community_mock_harness.dart';
import 'her_shell_fakes.dart';

/// Her shell over quiet fakes: the Dashboard's counters failed (a still
/// screen), sockets that never connect, and two stand-in routes — the inbox,
/// where she can tap a case row or leave, and a chat.
class HerShellRig {
  HerShellRig({
    this.launchedBy,
    UserEntity user = fakeMatchmaker,
    this.layers,
  }) {
    signInForTest(user);
    registerQuietShell(badges);
    addTearDown(opened.close);
  }

  /// The push whose tap launched the app.
  final RemoteMessage? launchedBy;

  /// What pushed screens need above the navigator; connectivity alone when
  /// null.
  final Widget Function(Widget navigator)? layers;

  /// Pushes tapped while the app runs.
  final opened = StreamController<RemoteMessage>.broadcast();

  final badges = ShellBadges();

  /// What each chat was opened with.
  final List<Object?> chats = [];

  int inboxOpens = 0;

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      onGenerateRoute: _route,
      builder: (_, navigator) =>
          layers?.call(navigator!) ??
          BlocProvider<ConnectivityCubit>(
            create: (_) => ConnectivityCubit(service: FakeConnectivity()),
            child: navigator!,
          ),
      child: MatchmakerHomeScreen(
        pushTaps: MatchmakerPushTaps(
          opened: opened.stream,
          initial: () async => launchedBy,
        ),
      ),
    );
  }

  /// The tab showing.
  int tab(WidgetTester tester) => tester
      .widget<ScrollHidingNavScaffold>(
        find.byType(ScrollHidingNavScaffold, skipOffstage: false),
      )
      .currentIndex;

  /// Whether the tab showing was reached from a notification.
  bool trail(WidgetTester tester) => tester
      .widget<MatchmakerHomeShellScope>(
        find.byType(MatchmakerHomeShellScope, skipOffstage: false),
      )
      .fromNotification;

  Route<Object?>? _route(RouteSettings settings) => switch (settings.name) {
    RouteNames.matchmakerNotifications => _page(settings, _inbox),
    RouteNames.matchmakerUserChat => _page(settings, (_) {
      chats.add(settings.arguments);
      return const Scaffold(body: Text('chat'));
    }),
    _ => null,
  };

  Widget _inbox(BuildContext context) {
    inboxOpens++;
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(const OpenCases()),
            child: const Text('a case row'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('leave'),
          ),
        ],
      ),
    );
  }

  static Route<Object?> _page(RouteSettings settings, WidgetBuilder page) =>
      MaterialPageRoute<Object?>(settings: settings, builder: page);
}

/// A push's `data`, as Firebase hands it over.
RemoteMessage push(Map<String, dynamic> data) => RemoteMessage(data: data);
