import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/features/matchmaker/conversations/domain/repositories/matchmaker_conversations_repository.dart';
import 'package:qeran/features/matchmaker/conversations/domain/usecases/open_user_chat_usecase.dart';
import 'package:qeran/features/matchmaker/conversations/presentation/blocs/matchmaker_open_chat_cubit.dart';
import 'package:qeran/features/matchmaker/dashboard/domain/entities/matchmaker_dashboard_stats.dart';
import 'package:qeran/features/matchmaker/dashboard/domain/repositories/matchmaker_dashboard_repository.dart';
import 'package:qeran/features/matchmaker/dashboard/domain/usecases/get_matchmaker_dashboard_usecase.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/blocs/matchmaker_dashboard_state.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_user_row.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_users_list.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_users_page.dart';
import 'package:qeran/features/matchmaker/users/domain/repositories/matchmaker_user_actions_repository.dart';
import 'package:qeran/features/matchmaker/users/domain/repositories/matchmaker_users_repository.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/subscription_plan.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/approve_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/approve_user_image_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/fetch_matchmaker_users_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/reject_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/request_image_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_user_actions_cubit.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_users_list_cubit.dart';
import 'package:qeran/features/matchmaker/users/presentation/widgets/matchmaker_users_list_view.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M1 — the "بالانتظار" badge must not outlive the row it counted.
///
/// The badge is fed by the DASHBOARD's `pendingUsersCount`, not by the pending
/// list. Approving or rejecting removed the row and refreshed the list, but
/// left the count untouched — so a "1" sat over a visibly empty list until the
/// matchmaker pulled to refresh the dashboard tab.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Serves one pending row on the first fetch and none afterwards — the row
/// "leaves" exactly as it does in production once approved or rejected.
class _FakeUsersRepository implements MatchmakerUsersRepository {
  int fetches = 0;

  @override
  Future<Either<Failure, MatchmakerUsersPage>> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
    int? planId,
    Gender? gender,
  }) async {
    fetches++;
    return Right(
      MatchmakerUsersPage(
        items: fetches == 1
            ? const [
                MatchmakerUserRow(
                  userId: 'u1',
                  fullName: 'أنس',
                  profileImageUrl: null,
                  assignedAt: null,
                  hasProfileImage: true,
                ),
              ]
            : const [],
        pageNumber: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getSubscriptionPlans() async =>
      const Right([]);
}

/// Counts dashboard fetches — the badge's source of truth.
class _FakeDashboardRepository implements MatchmakerDashboardRepository {
  int fetches = 0;

  @override
  Future<Either<Failure, MatchmakerDashboardStats>> getDashboard() async {
    fetches++;
    // 1 pending before the action, 0 after — what the server would report.
    return Right(
      MatchmakerDashboardStats(
        pendingUsersCount: fetches <= 1 ? 1 : 0,
        approvedSubscribedCount: 0,
        approvedUnsubscribedCount: 0,
        activeCompatibilityCasesCount: 0,
        unreadMessagesCount: 0,
        totalAssignedUsers: 1,
      ),
    );
  }
}

class _StubActionsRepository implements MatchmakerUserActionsRepository {
  @override
  Future<Either<Failure, String>> approveImage({
    required String userId,
    required String imageId,
  }) async => const Right('ok');

  @override
  Future<Either<Failure, String>> approve(String userId) async =>
      const Right('ok');

  @override
  Future<Either<Failure, String>> reject({
    required String userId,
    required String reason,
  }) async => const Right('ok');

  @override
  Future<Either<Failure, String>> requestImage(String userId) async =>
      const Right('ok');
}

class _StubConversationsRepository extends Fake
    implements MatchmakerConversationsRepository {}

late _FakeUsersRepository _usersRepo;
late _FakeDashboardRepository _dashboardRepo;
late MatchmakerDashboardCubit _dashboardCubit;

Future<void> _pumpPendingList(WidgetTester tester) async {
  _usersRepo = _FakeUsersRepository();
  _dashboardRepo = _FakeDashboardRepository();
  final actionsRepo = _StubActionsRepository();

  sl.registerFactoryParam<MatchmakerUsersListCubit, MatchmakerUsersList, void>(
    (list, _) => MatchmakerUsersListCubit(
      list: list,
      fetchUsers: FetchMatchmakerUsersUseCase(_usersRepo),
    ),
  );
  sl.registerFactoryParam<MatchmakerUserActionsCubit, String, void>(
    (userId, _) => MatchmakerUserActionsCubit(
      userId: userId,
      approve: ApproveUserUseCase(actionsRepo),
      reject: RejectUserUseCase(actionsRepo),
      requestImage: RequestImageUserUseCase(actionsRepo),
      approveImage: ApproveUserImageUseCase(actionsRepo),
    ),
  );
  sl.registerFactory<MatchmakerOpenChatCubit>(
    () => MatchmakerOpenChatCubit(
      openUserChat: OpenUserChatUseCase(_StubConversationsRepository()),
    ),
  );

  _dashboardCubit = MatchmakerDashboardCubit(
    getDashboard: GetMatchmakerDashboardUseCase(_dashboardRepo),
  );
  await _dashboardCubit.load();

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<MatchmakerDashboardCubit>.value(
              value: _dashboardCubit,
              child: const Scaffold(
                body: MatchmakerUsersListView(
                  list: MatchmakerUsersList.pending,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

int get _badgeCount {
  final state = _dashboardCubit.state;
  return state is MatchmakerDashboardLoaded ? state.stats.pendingUsersCount : -1;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());
  tearDown(() async => _dashboardCubit.close());

  testWidgets('approving a pending user refetches the badge count', (
    tester,
  ) async {
    await _pumpPendingList(tester);
    expect(_badgeCount, 1);
    expect(_dashboardRepo.fetches, 1);

    await tester.tap(
      find.text(LocaleKeys.matchmaker_users_action_approve).first,
    );
    await tester.pumpAndSettle();
    // The sheet's own موافقة — the row card's button is still on screen behind
    // it, so target the last match.
    await tester.tap(find.text(LocaleKeys.matchmaker_users_action_approve).last);
    await tester.pumpAndSettle();
    // Drain the success snackbar's auto-dismiss timer.
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // Both the list AND the count were invalidated by the same action.
    expect(_usersRepo.fetches, greaterThan(1));
    expect(_dashboardRepo.fetches, 2);
    expect(_badgeCount, 0, reason: 'badge must not outlive the row');
  });

  testWidgets('rejecting a pending user refetches the badge count too', (
    tester,
  ) async {
    await _pumpPendingList(tester);
    expect(_badgeCount, 1);

    await tester.tap(
      find.text(LocaleKeys.matchmaker_users_action_approve).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(LocaleKeys.matchmaker_profile_action_reject));
    await tester.pumpAndSettle();
    // Reject opens the reason sheet first.
    await tester.enterText(find.byType(TextField).first, 'سبب');
    await tester.pumpAndSettle();
    await tester.tap(find.text(LocaleKeys.matchmaker_profile_reject_submit));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(_dashboardRepo.fetches, 2);
    expect(_badgeCount, 0);
  });
}
