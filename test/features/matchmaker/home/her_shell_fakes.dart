import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/state/paginated_list_state.dart';
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
import 'package:qeran/features/matchmaker/shared/domain/entities/matchmaker_realtime_status.dart';
import 'package:qeran/features/matchmaker/shared/domain/ports/matchmaker_realtime_port.dart';

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

/// What her shell reads from the container, quiet: sockets that never
/// connect, the Dashboard's counters failed (a still screen), an empty Cases
/// tab, and [badges].
void registerQuietShell(BadgesCubit badges) {
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
}

MatchmakerDashboardCubit _stillDashboard() {
  final dashboard = _StillDashboard();
  when(
    () => dashboard.state,
  ).thenReturn(const MatchmakerDashboardError('offline'));
  when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());
  when(dashboard.load).thenAnswer((_) async {});
  when(dashboard.close).thenAnswer((_) async {});
  return dashboard;
}

MatchmakerCasesListCubit _quietCases() {
  final cases = _QuietCases();
  when(() => cases.state).thenReturn(const PaginatedListState());
  when(() => cases.stream).thenAnswer((_) => const Stream.empty());
  when(cases.loadFirst).thenAnswer((_) async {});
  when(cases.close).thenAnswer((_) async {});
  return cases;
}
