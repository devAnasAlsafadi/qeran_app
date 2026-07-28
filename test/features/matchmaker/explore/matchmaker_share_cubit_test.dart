import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/repositories/chat_repository.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/matchmaker/conversations/domain/repositories/matchmaker_conversations_repository.dart';
import 'package:qeran/features/matchmaker/conversations/domain/usecases/open_user_chat_usecase.dart';
import 'package:qeran/features/matchmaker/explore/presentation/blocs/share/matchmaker_share_cubit.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_user_row.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_users_list.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_users_page.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/subscription_plan.dart';
import 'package:qeran/features/matchmaker/users/domain/repositories/matchmaker_users_repository.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/fetch_matchmaker_users_usecase.dart';

MatchmakerUserRow _row(String id) => MatchmakerUserRow(
  userId: id,
  fullName: id,
  profileImageUrl: null,
  assignedAt: null,
);

/// Serves a canned page per (list, page) and records what was asked for.
class _FakeUsersRepository implements MatchmakerUsersRepository {
  _FakeUsersRepository(this.pages);

  /// list -> page number -> page.
  final Map<MatchmakerUsersList, Map<int, MatchmakerUsersPage>> pages;
  final List<(MatchmakerUsersList, int)> calls = [];
  final List<Gender?> genders = [];

  @override
  Future<Either<Failure, MatchmakerUsersPage>> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
    int? planId,
    Gender? gender,
  }) async {
    calls.add((list, page));
    genders.add(gender);
    final found = pages[list]?[page];
    if (found == null) {
      return const Left(ServerFailure(message: 'unexpected fetch'));
    }
    return Right(found);
  }

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getSubscriptionPlans() async =>
      const Right([]);
}

class _UnusedConversationsRepository
    implements MatchmakerConversationsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not exercised by these tests');
}

class _UnusedChatRepository implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not exercised by these tests');
}

MatchmakerShareCubit _cubit(_FakeUsersRepository repo) => MatchmakerShareCubit(
  sharedUserId: 'candidate',
  fetchUsers: FetchMatchmakerUsersUseCase(repo),
  openChat: OpenUserChatUseCase(_UnusedConversationsRepository()),
  shareProfile: ShareProfileUseCase(_UnusedChatRepository()),
);

void main() {
  test(
    'a short unsubscribed source still pulls the subscribed source',
    () async {
      // The reported bug: 6 unsubscribed users fit on screen, so the sheet's
      // scroll listener never fired, loadMore was never called, and every
      // SUBSCRIBED user was silently missing from the picker.
      final repo = _FakeUsersRepository({
        MatchmakerUsersList.approvedUnsubscribed: {
          1: MatchmakerUsersPage(
            items: [_row('anas'), _row('diaa')],
            pageNumber: 1,
            totalPages: 1,
          ),
        },
        MatchmakerUsersList.approvedSubscribed: {
          1: MatchmakerUsersPage(
            items: [_row('rami'), _row('ali')],
            pageNumber: 1,
            totalPages: 1,
          ),
        },
      });

      final cubit = _cubit(repo);
      await cubit.loadFirst();
      // Let the chained bridge fetch settle.
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state.recipients.map((r) => r.userId),
        ['anas', 'diaa', 'rami', 'ali'],
        reason: 'both approved sources must be present without any scrolling',
      );
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.loadingMore, isFalse);
      await cubit.close();
    },
  );

  test('an empty first source bridges without flashing an empty list', () async {
    final repo = _FakeUsersRepository({
      MatchmakerUsersList.approvedUnsubscribed: {
        1: const MatchmakerUsersPage(items: [], pageNumber: 1, totalPages: 1),
      },
      MatchmakerUsersList.approvedSubscribed: {
        1: MatchmakerUsersPage(
          items: [_row('rami')],
          pageNumber: 1,
          totalPages: 1,
        ),
      },
    });

    final cubit = _cubit(repo);
    final seen = <bool>[];
    final sub = cubit.stream.listen((s) => seen.add(s.loading));

    await cubit.loadFirst();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.recipients.map((r) => r.userId), ['rami']);
    // While bridging on a still-empty list we stay in the loading state, so
    // the sheet never renders a false "no recipients" frame.
    expect(seen.first, isTrue);
    expect(cubit.state.loading, isFalse);
    await sub.cancel();
    await cubit.close();
  });

  test('a source with more pages is NOT eagerly drained', () async {
    final repo = _FakeUsersRepository({
      MatchmakerUsersList.approvedUnsubscribed: {
        1: MatchmakerUsersPage(
          items: [_row('a')],
          pageNumber: 1,
          totalPages: 3,
        ),
      },
      MatchmakerUsersList.approvedSubscribed: const {},
    });

    final cubit = _cubit(repo);
    await cubit.loadFirst();
    await Future<void>.delayed(Duration.zero);

    // Only page 1 was requested — bridging must never turn into eager
    // pagination of the whole list.
    expect(repo.calls, [(MatchmakerUsersList.approvedUnsubscribed, 1)]);
    expect(cubit.state.hasMore, isTrue);
    await cubit.close();
  });

  group('recipient gender filter (#12b)', () {
    _FakeUsersRepository singlePageRepo() => _FakeUsersRepository({
      MatchmakerUsersList.approvedUnsubscribed: const {
        1: MatchmakerUsersPage(items: [], pageNumber: 1, totalPages: 1),
      },
      MatchmakerUsersList.approvedSubscribed: const {
        1: MatchmakerUsersPage(items: [], pageNumber: 1, totalPages: 1),
      },
    });

    test('unset by default — nothing sends a gender today', () async {
      // The picker's endpoints do not accept ?gender= yet, so no control sets
      // it and every fetch must go out unfiltered.
      final repo = singlePageRepo();
      final cubit = _cubit(repo);

      await cubit.loadFirst();
      await Future<void>.delayed(Duration.zero);

      expect(repo.genders, everyElement(isNull));
      await cubit.close();
    });

    test('setGender threads through to every source', () async {
      final repo = singlePageRepo();
      final cubit = _cubit(repo);

      await cubit.setGender(Gender.female);
      await Future<void>.delayed(Duration.zero);

      expect(repo.genders, isNotEmpty);
      expect(repo.genders, everyElement(Gender.female));
      await cubit.close();
    });

    test('setGender restarts from page 1', () async {
      final repo = singlePageRepo();
      final cubit = _cubit(repo);
      await cubit.loadFirst();
      await Future<void>.delayed(Duration.zero);
      repo.calls.clear();

      await cubit.setGender(Gender.male);
      await Future<void>.delayed(Duration.zero);

      // A filter change invalidates what is already listed, so it reloads
      // rather than appending onto the unfiltered results.
      expect(repo.calls.first, (MatchmakerUsersList.approvedUnsubscribed, 1));
      await cubit.close();
    });

    test('setting the same gender twice does not refetch', () async {
      final repo = singlePageRepo();
      final cubit = _cubit(repo);
      await cubit.setGender(Gender.male);
      await Future<void>.delayed(Duration.zero);
      repo.calls.clear();

      await cubit.setGender(Gender.male);
      await Future<void>.delayed(Duration.zero);

      expect(repo.calls, isEmpty);
      await cubit.close();
    });
  });
}
