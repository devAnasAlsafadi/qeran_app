import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/domain/entities/like_action_outcome.dart';
import 'package:qeran/features/likes/domain/entities/like_requests_data.dart';
import 'package:qeran/features/likes/domain/entities/likes_tab.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
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

  group('acceptLike', () {
    test(
      'success → emits acceptSuccess, reloads incoming, invalidates matches',
      () async {
        when(() => accept(42)).thenAnswer(
          (_) async => const Right<Failure, LikeActionOutcome>(
            LikeActionSuccess(serverMessage: 'تم القبول'),
          ),
        );
        when(() => incoming()).thenAnswer(
          (_) async => const Right<Failure, LikeRequestsData>(_empty),
        );

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
        when(() => accept(7)).thenAnswer(
          (_) async => const Right<Failure, LikeActionOutcome>(
            LikeActionRequiresSubscription(
              serverMessage: 'الاشتراك مطلوب لقبول الإعجابات',
            ),
          ),
        );

        await cubit.acceptLike(7);

        expect(
          cubit.state.actionEvent,
          LikesActionEvent.acceptRequiresSubscription,
        );
        verifyNever(() => incoming());
      },
    );

    test('rapid duplicate taps while in-flight → ignored', () async {
      final gate = Completer<Either<Failure, LikeActionOutcome>>();
      when(() => accept(5)).thenAnswer((_) => gate.future);
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

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
  });

  group('rejectLike', () {
    test('success → emits rejectSuccess + refresh', () async {
      when(() => reject(42)).thenAnswer(
        (_) async => const Right<Failure, LikeActionOutcome>(
          LikeActionSuccess(serverMessage: 'تم الرفض'),
        ),
      );
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

      await cubit.rejectLike(42);

      expect(cubit.state.actionEvent, LikesActionEvent.rejectSuccess);
      verify(() => incoming()).called(1);
    });
  });

}
