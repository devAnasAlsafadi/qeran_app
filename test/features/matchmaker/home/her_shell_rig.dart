import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/state/paginated_list_state.dart';
import 'package:qeran/core/widgets/scroll_hiding_nav_scaffold.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/chat/domain/entities/badge_update_event.dart';
import 'package:qeran/features/chat/domain/entities/realtime_status.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/matchmaker/colleagues/domain/usecases/open_colleague_chat_usecase.dart';
import 'package:qeran/features/matchmaker/colleagues/presentation/blocs/matchmaker_colleague_open_chat_cubit.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/blocs/matchmaker_cases_list_cubit.dart';
import 'package:qeran/features/matchmaker/conversations/domain/usecases/open_user_chat_usecase.dart';
import 'package:qeran/features/matchmaker/conversations/presentation/blocs/matchmaker_open_chat_cubit.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/blocs/matchmaker_dashboard_state.dart';
import 'package:qeran/features/matchmaker/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/matchmaker/home/presentation/matchmaker_push_taps.dart';
import 'package:qeran/features/matchmaker/home/presentation/screens/matchmaker_home_screen.dart';
import 'package:qeran/features/matchmaker/shared/data/matchmaker_notification_router.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/matchmaker_realtime_status.dart';
import 'package:qeran/features/matchmaker/shared/domain/ports/matchmaker_realtime_port.dart';

import '../../../core/shipped_strings_rig.dart';
import '../../auth/presentation/fake_session.dart';
import '../../community/fixtures/community_mock_harness.dart';

class _QuietRealtime extends Fake implements MatchmakerRealtimePort {
  @override
  MatchmakerRealtimeStatus get status => MatchmakerRealtimeStatus.disconnected;
  @override
  Stream<MatchmakerRealtimeStatus> get statusStream => const Stream.empty();
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
}

class _QuietChat extends Fake implements ChatRealtimePort {
  @override
  RealtimeStatus get status => RealtimeStatus.disconnected;
  @override
  Stream<RealtimeStatus> get statusStream => const Stream.empty();
  @override
  Stream<BadgeUpdateEvent> get badgeUpdates => const Stream.empty();
  @override
  Future<void> connect({
    required ChatAccessTokenProvider accessTokenProvider,
  }) async {}
  @override
  Future<void> disconnect() async {}
}

class _StillDashboard extends Mock implements MatchmakerDashboardCubit {}

class _QuietCases extends Mock implements MatchmakerCasesListCubit {}

class _FakeOpenUserChat extends Fake implements OpenUserChatUseCase {}

class _FakeOpenColleague extends Fake implements OpenColleagueChatUseCase {}

class _FakeGet extends Fake implements GetBadgesUseCase {}

class _FakeMark extends Fake implements MarkTabSeenUseCase {}

/// Her badges, recording the tabs she opened, never on the network.
class ShellBadges extends BadgesCubit {
  ShellBadges() : super(getBadges: _FakeGet(), markTabSeen: _FakeMark());

  final List<String> seen = [];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markSeen(String tabKey) async => seen.add(tabKey);
}

/// Her shell over quiet fakes: the Dashboard's counters failed (a still
/// screen), sockets that never connect, and two stand-in routes — the inbox,
/// where she can tap a case row or leave, and a chat.
class HerShellRig {
  HerShellRig({this.launchedBy, UserEntity user = fakeMatchmaker}) {
    signInForTest(user);
    sl
      ..registerSingleton<MatchmakerRealtimePort>(_QuietRealtime())
      ..registerSingleton<ChatRealtimePort>(_QuietChat())
      ..registerSingleton<ChatAccessTokenProvider>(() async => 'jwt')
      ..registerSingleton<BadgesCubit>(badges)
      ..registerFactory<MatchmakerDashboardCubit>(_stillDashboard)
      ..registerFactory<MatchmakerCasesListCubit>(_quietCases)
      ..registerFactory(
        () => MatchmakerOpenChatCubit(openUserChat: _FakeOpenUserChat()),
      )
      ..registerFactory(
        () => MatchmakerColleagueOpenChatCubit(
          openColleagueChat: _FakeOpenColleague(),
        ),
      );
    addTearDown(opened.close);
  }

  /// The push whose tap launched the app.
  final RemoteMessage? launchedBy;

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
      builder: (_, navigator) => BlocProvider<ConnectivityCubit>(
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

  static MatchmakerDashboardCubit _stillDashboard() {
    final dashboard = _StillDashboard();
    when(
      () => dashboard.state,
    ).thenReturn(const MatchmakerDashboardError('offline'));
    when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());
    when(dashboard.load).thenAnswer((_) async {});
    when(dashboard.close).thenAnswer((_) async {});
    return dashboard;
  }

  static MatchmakerCasesListCubit _quietCases() {
    final cases = _QuietCases();
    when(() => cases.state).thenReturn(const PaginatedListState());
    when(() => cases.stream).thenAnswer((_) => const Stream.empty());
    when(cases.loadFirst).thenAnswer((_) async {});
    when(cases.close).thenAnswer((_) async {});
    return cases;
  }
}

/// A push's `data`, as Firebase hands it over.
RemoteMessage push(Map<String, dynamic> data) => RemoteMessage(data: data);
