import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/domain/entities/like_action_outcome.dart';
import 'package:qeran/features/likes/domain/entities/like_requests_data.dart';
import 'package:qeran/features/likes/domain/entities/likes_tab.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/usecases/accept_like_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_incoming_likes_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_matches_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_outgoing_likes_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_like_usecase.dart';
import 'package:qeran/features/likes/presentation/blocs/likes_cubit.dart';
import 'package:qeran/features/likes/presentation/blocs/likes_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

class _MockIncoming extends Mock implements GetIncomingLikesUseCase {}

class _MockOutgoing extends Mock implements GetOutgoingLikesUseCase {}

class _MockAccept extends Mock implements AcceptLikeUseCase {}

class _MockReject extends Mock implements RejectLikeUseCase {}

class _MockGetMatches extends Mock implements GetMatchesUseCase {}

class _MockProfileGate extends Mock implements ProfileGateCubit {}

const _empty = LikeRequestsData(
  pending: [],
  archived: [],
  requiresSubscription: false,
);

const List<MatchCard> _noMatches = <MatchCard>[];

MatchCard _match(int id, {DateTime? at, MatchCaseStatus? status}) => MatchCard(
  likeRequestId: id,
  otherUserId: 'u$id',
  otherUserName: 'User $id',
  images: const [],
  stage: MatchStage.photosExchanged,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
  caseStatus: status ?? MatchCaseStatus.active,
  lastActivityAt: at,
);

void main() {
  late _MockIncoming incoming;
  late _MockOutgoing outgoing;
  late _MockAccept accept;
  late _MockReject reject;
  late _MockGetMatches getMatches;
  late _MockProfileGate profileGate;
  late LikesCubit cubit;

  setUp(() {
    incoming = _MockIncoming();
    outgoing = _MockOutgoing();
    accept = _MockAccept();
    reject = _MockReject();
    getMatches = _MockGetMatches();
    profileGate = _MockProfileGate();
    when(() => profileGate.isGated).thenReturn(false);
    cubit = LikesCubit(
      getIncoming: incoming,
      getOutgoing: outgoing,
      acceptLike: accept,
      rejectLike: reject,
      getMatches: getMatches,
      profileGate: profileGate,
    );
  });

  tearDown(() => cubit.close());

  test('loadOutgoing success → status loaded + data set', () async {
    when(
      () => outgoing(),
    ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

    await cubit.loadOutgoing();

    expect(cubit.state.outgoingStatus, LikesAsyncStatus.loaded);
    expect(cubit.state.outgoing, _empty);
    expect(cubit.state.outgoingErrorKey, isNull);
  });

  test('loadOutgoing failure → status failure + error key', () async {
    when(() => outgoing()).thenAnswer(
      (_) async => const Left<Failure, LikeRequestsData>(
        ServerFailure(message: 'errors.unexpected'),
      ),
    );

    await cubit.loadOutgoing();

    expect(cubit.state.outgoingStatus, LikesAsyncStatus.failure);
    expect(cubit.state.outgoingErrorKey, 'errors.unexpected');
  });

  test('switchTab to received triggers loadIncoming exactly once', () async {
    when(
      () => incoming(),
    ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

    cubit.switchTab(LikesTab.received);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.activeTab, LikesTab.received);
    expect(cubit.state.incomingStatus, LikesAsyncStatus.loaded);
    verify(() => incoming()).called(1);
  });

  test('switchTab to matches triggers loadMatches exactly once', () async {
    when(() => getMatches()).thenAnswer(
      (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
    );

    cubit.switchTab(LikesTab.matches);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.activeTab, LikesTab.matches);
    expect(cubit.state.matchesStatus, LikesAsyncStatus.loaded);
    verify(() => getMatches()).called(1);
  });

  test(
    'switchTab back-and-forth does not re-fetch a tab that is loaded',
    () async {
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
      when(
        () => outgoing(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      cubit.switchTab(LikesTab.received);
      await Future<void>.delayed(Duration.zero);
      cubit.switchTab(LikesTab.matches);
      await Future<void>.delayed(Duration.zero);
      cubit.switchTab(LikesTab.sent);
      await Future<void>.delayed(Duration.zero);
      cubit.switchTab(LikesTab.received);
      await Future<void>.delayed(Duration.zero);
      cubit.switchTab(LikesTab.matches);
      await Future<void>.delayed(Duration.zero);

      verify(() => incoming()).called(1);
      verify(() => outgoing()).called(1);
      verify(() => getMatches()).called(1);
    },
  );

  test('refresh on matches tab delegates to loadMatches', () async {
    when(() => getMatches()).thenAnswer(
      (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
    );

    cubit.switchTab(LikesTab.matches);
    await Future<void>.delayed(Duration.zero);
    await cubit.refresh();

    verify(() => getMatches()).called(2);
    verifyNever(() => incoming());
    verifyNever(() => outgoing());
  });

  test('close before usecase completes does not throw', () async {
    final completer = Completer<Either<Failure, LikeRequestsData>>();
    when(() => outgoing()).thenAnswer((_) => completer.future);

    final pending = cubit.loadOutgoing();
    await cubit.close();
    completer.complete(const Right<Failure, LikeRequestsData>(_empty));

    await expectLater(pending, completes);
  });

  // ── Like accept / reject ──────────────────────────────────────────────
  //
  // Both families are covered from a mapping TABLE, generated into one test
  // per case rather than looped inside a single test. Each case then gets a
  // fresh cubit and fresh mocks from `setUp`, so `verify` / `verifyNever`
  // need nothing cleared between iterations — the trap a shared counter
  // walks into, and the reason this file needs no counter at all.
  //
  // Driven through the cubit rather than against `acceptLikeEvent` /
  // `rejectLikeEvent` directly, because half of what can go wrong here is
  // the WIRING: the two mappers take the same argument and return the same
  // enum, so calling the wrong one from the wrong method compiles.

  group('acceptLike', () {
    void serverSays(LikeActionOutcome outcome) {
      when(
        () => accept(42),
      ).thenAnswer((_) async => Right<Failure, LikeActionOutcome>(outcome));
    }

    void listReloads() {
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
    }

    // Every answer the accept endpoint can give, and the event it becomes.
    const outcomes = <LikeActionOutcome, LikesActionEvent>{
      LikeActionSuccess(serverMessage: ''): LikesActionEvent.acceptSuccess,
      LikeActionRequiresSubscription(serverMessage: ''):
          LikesActionEvent.acceptRequiresSubscription,
      LikeActionExpired(serverMessage: ''): LikesActionEvent.acceptExpired,
      LikeActionNotFoundOrExpired(serverMessage: ''):
          LikesActionEvent.acceptNotFound,
      LikeActionProfileUnderReview(serverMessage: ''):
          LikesActionEvent.acceptUnderReview,
      LikeActionFailure(serverMessage: ''): LikesActionEvent.acceptFailure,
    };

    test('every outcome the server can send is listed', () {
      expect(
        outcomes.length,
        6,
        reason:
            'LikeActionOutcome is sealed with six members. A seventh is a '
            'compile error inside acceptLikeEvent but NOT in this table, so '
            'the new answer would ship with no test at all. Add its row.',
      );
    });

    test('every outcome reaches an event of its own', () {
      expect(outcomes.values.toSet().length, outcomes.length);
    });

    for (final entry in outcomes.entries) {
      test('${entry.key.runtimeType} reports ${entry.value.name}', () async {
        listReloads();
        serverSays(entry.key);

        await cubit.acceptLike(42);

        expect(cubit.state.actionEvent, entry.value);
      });
    }

    // The shared refetch rule, accept half: refetch when the answer proves
    // the ROW stale — acted on, gone, or expired. Not when it gates the
    // MEMBER (subscription, under review), where the row is exactly as drawn
    // and a refetch buys a round trip to redraw it. Never on a transport
    // failure, where the server said nothing to act on.
    const refetching = {
      LikesActionEvent.acceptSuccess,
      LikesActionEvent.acceptExpired,
      LikesActionEvent.acceptNotFound,
    };

    for (final entry in outcomes.entries) {
      final refetches = refetching.contains(entry.value);
      test(
        '${entry.value.name} '
        '${refetches ? 'refetches' : 'leaves'} the Received list',
        () async {
          listReloads();
          serverSays(entry.key);

          await cubit.acceptLike(42);

          if (refetches) {
            verify(() => incoming()).called(1);
          } else {
            verifyNever(() => incoming());
          }
        },
      );
    }

    test(
      'success → emits acceptSuccess, reloads incoming, invalidates matches',
      () async {
        serverSays(const LikeActionSuccess(serverMessage: 'تم القبول'));
        listReloads();

        await cubit.acceptLike(42);

        expect(cubit.state.actionEvent, LikesActionEvent.acceptSuccess);
        expect(
          cubit.state.matchesStatus,
          LikesAsyncStatus.initial,
          reason: 'matches slot is invalidated so next visit refetches',
        );
        verify(() => accept(42)).called(1);
        verify(() => incoming()).called(1);
      },
    );

    test(
      'requiresSubscription → paywall event, NO refresh, NO invalidation',
      () async {
        when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
        );
        serverSays(
          const LikeActionRequiresSubscription(
            serverMessage: 'الاشتراك مطلوب لقبول الإعجابات',
          ),
        );
        await cubit.loadMatches();

        await cubit.acceptLike(42);

        expect(
          cubit.state.actionEvent,
          LikesActionEvent.acceptRequiresSubscription,
        );
        // The "NO invalidation" half of the name, which this test used to
        // claim without asserting. Loading matches first is what makes it
        // mean anything — `initial` is also the value it starts at.
        expect(
          cubit.state.matchesStatus,
          LikesAsyncStatus.loaded,
          reason:
              'a paywall refusal creates no match, so the cached list must '
              'survive it — invalidating here costs a refetch to redraw the '
              'same rows',
        );
        verifyNever(() => incoming());
      },
    );

    test('rapid duplicate taps while in-flight → ignored', () async {
      final gate = Completer<Either<Failure, LikeActionOutcome>>();
      when(() => accept(5)).thenAnswer((_) => gate.future);
      listReloads();

      final first = cubit.acceptLike(5);
      expect(cubit.state.isAccepting(5), isTrue);
      final second = cubit.acceptLike(5);
      await second;
      gate.complete(
        const Right<Failure, LikeActionOutcome>(
          LikeActionSuccess(serverMessage: 'ok'),
        ),
      );
      await first;

      verify(() => accept(5)).called(1);
    });

    // The pre-gate exists so an unapproved member does not spend a round
    // trip learning what the app already knows.
    test('an unapproved profile never reaches the server', () async {
      when(() => profileGate.isGated).thenReturn(true);

      await cubit.acceptLike(42);

      expect(cubit.state.actionEvent, LikesActionEvent.acceptUnderReview);
      verifyNever(() => accept(any()));
    });
  });

  group('rejectLike', () {
    void serverSays(LikeActionOutcome outcome) {
      when(
        () => reject(42),
      ).thenAnswer((_) async => Right<Failure, LikeActionOutcome>(outcome));
    }

    void listReloads() {
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
    }

    // The same six server answers, mapped for the other verb. Three of them
    // collapse into one generic failure, which is why this family has no
    // "an event of its own" test — see the escalation guard below.
    const outcomes = <LikeActionOutcome, LikesActionEvent>{
      LikeActionSuccess(serverMessage: ''): LikesActionEvent.rejectSuccess,
      LikeActionExpired(serverMessage: ''): LikesActionEvent.rejectExpired,
      LikeActionNotFoundOrExpired(serverMessage: ''):
          LikesActionEvent.rejectNotFound,
      LikeActionRequiresSubscription(serverMessage: ''):
          LikesActionEvent.rejectFailure,
      LikeActionProfileUnderReview(serverMessage: ''):
          LikesActionEvent.rejectFailure,
      LikeActionFailure(serverMessage: ''): LikesActionEvent.rejectFailure,
    };

    test('every outcome the server can send is listed', () {
      expect(
        outcomes.length,
        6,
        reason:
            'LikeActionOutcome is sealed with six members, and reject has to '
            'answer all of them even though three share an event. A seventh '
            'is a compile error inside rejectLikeEvent but NOT here.',
      );
    });

    for (final entry in outcomes.entries) {
      test('${entry.key.runtimeType} reports ${entry.value.name}', () async {
        listReloads();
        serverSays(entry.key);

        await cubit.rejectLike(42);

        expect(cubit.state.actionEvent, entry.value);
      });
    }

    // THE guard on this family, and the reason the collapse above is a
    // product decision rather than three arms nobody got round to splitting.
    test('a decline never becomes a paywall or a review notice', () async {
      // What `likes_screen._onActionEvent` does with the accept twins of the
      // two answers below: opens the subscription sheet, and tells the member
      // their profile is still under review.
      const escalating = {
        LikesActionEvent.acceptRequiresSubscription,
        LikesActionEvent.acceptUnderReview,
      };
      const collapsed = [
        LikeActionRequiresSubscription(serverMessage: 'الاشتراك مطلوب'),
        LikeActionProfileUnderReview(serverMessage: 'ملفك قيد المراجعة'),
      ];
      listReloads();

      for (final outcome in collapsed) {
        serverSays(outcome);

        await cubit.rejectLike(42);

        expect(
          escalating,
          isNot(contains(cubit.state.actionEvent)),
          reason:
              'Declining a like is neither subscription-gated nor '
              'approval-gated server-side, so ${outcome.runtimeType} on a '
              'reject is the backend saying something that cannot be about '
              'this action. Routing it to its accept twin would open the '
              'PAYWALL, or show "profile under review", on a DECLINE — '
              'asking a member to pay, or to wait for approval, in order to '
              'say no. If the backend has started gating reject, change '
              'rejectLikeEvent and this test together.',
        );
        expect(cubit.state.actionEvent, LikesActionEvent.rejectFailure);
      }
    });

    // The reject half of the shared rule. `rejectFailure` covers all three
    // non-refetching answers at once, so these cases are named by the server
    // answer rather than by the event, which would collide.
    const refetching = {
      LikesActionEvent.rejectSuccess,
      LikesActionEvent.rejectExpired,
      LikesActionEvent.rejectNotFound,
    };

    for (final entry in outcomes.entries) {
      final refetches = refetching.contains(entry.value);
      test(
        '${entry.key.runtimeType} '
        '${refetches ? 'refetches' : 'leaves'} the Received list',
        () async {
          listReloads();
          serverSays(entry.key);

          await cubit.rejectLike(42);

          if (refetches) {
            verify(() => incoming()).called(1);
          } else {
            verifyNever(() => incoming());
          }
        },
      );
    }

    // Declining is not an outward action, so it is not approval-gated the
    // way accepting is — the same asymmetry rejectLikeEvent encodes, checked
    // at the other end of the method.
    test('an unapproved profile can still decline', () async {
      when(() => profileGate.isGated).thenReturn(true);
      serverSays(const LikeActionSuccess(serverMessage: ''));
      listReloads();

      await cubit.rejectLike(42);

      expect(cubit.state.actionEvent, LikesActionEvent.rejectSuccess);
      verify(() => reject(42)).called(1);
    });
  });

  // The comparator has its own tests; this one asks a different question —
  // whether the list that reaches state went through it. A correct comparator
  // that nothing calls passes every test in `match_card_order_test` and ships
  // an unsorted list.
  test('loadMatches orders what it emits', () async {
    when(() => getMatches()).thenAnswer(
      (_) async => Right<Failure, List<MatchCard>>([
        _match(1, at: DateTime.utc(2026, 8, 1)),
        _match(2, at: DateTime.utc(2026, 8, 9), status: MatchCaseStatus.cancelled),
        _match(3, at: DateTime.utc(2026, 8, 5)),
      ]),
    );

    await cubit.loadMatches();

    expect(
      cubit.state.matches!.map((c) => c.likeRequestId).toList(),
      [3, 1, 2],
      reason:
          'the list reached state in the order the server sent it. The most '
          'recent card here is a CANCELLED one, so an unordered list and a '
          'recency-only order both differ from this.',
    );
  });
}
